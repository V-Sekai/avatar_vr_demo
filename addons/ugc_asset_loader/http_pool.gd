# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# http_pool.gd
# SPDX-License-Identifier: MIT

extends Node


class Future:
	signal completed(http: HTTPClient)


var next_request: int = 0
var pending_requests: Dictionary = {}  # int -> Future

var http_client_pool: Array[HTTPClient]
var total_http_clients: int = 0:
	set(value):
		while value < total_http_clients:
			if http_client_pool.is_empty():
				return
			http_client_pool.pop_back()
			total_http_clients -= 1
		while value > total_http_clients:
			http_client_pool.push_back(HTTPClient.new())
			total_http_clients += 1

signal http_tick


class HTTPState:
	const YIELD_PERIOD_MS = 50

	var out_path: String = ""
	var adapt_godot_resource_header: bool = false

	var http_pool: Node
	var http: HTTPClient
	var cancelled: bool = false

	var sent_request: bool = false
	var status: int
	var connect_err: int = OK

	var response_code: int
	var response_body: PackedByteArray
	var response_headers: Dictionary
	var file: FileAccess
	var bytes: int
	var total_bytes: int

	signal _connection_finished(http_client: HTTPClient)
	signal _request_finished(success: bool)

	signal download_progressed(bytes: int, total_bytes: int)

	func _init(p_http_pool: Node, p_http_client: HTTPClient):
		self.http = p_http_client
		self.http_pool = p_http_pool

	func set_output_path(p_out_path: String) -> void:
		self.out_path = p_out_path

	func cancel() -> void:
		cancelled = true

	func http_tick() -> void:
		print("HTTP: tick")
		if not sent_request:
			if cancelled:
				if file:
					file.close()
				cancelled = false
				http.close()
				_connection_finished.emit(null)
				return

			var _poll_error: int = http.poll()
			status = http.get_status()
			print("HTTP: Before sent, Status is now " + str(status))

			if status == HTTPClient.STATUS_CONNECTED or status == HTTPClient.STATUS_REQUESTING or status == HTTPClient.STATUS_BODY:
				print("HTTP: Connection finished")
				_connection_finished.emit(http)
			elif status != HTTPClient.STATUS_CONNECTING and status != HTTPClient.STATUS_RESOLVING and status != HTTPClient.STATUS_CONNECTED:
				printerr("HTTPPool: could not connect to host: status = %s" % [str(http.get_status())])
				_connection_finished.emit(null)
				return
			else:
				pass
		else:
			status = http.get_status()
			print("HTTP: After sent request, Status is now " + str(status))

			if status != HTTPClient.STATUS_REQUESTING and status != HTTPClient.STATUS_BODY:
				print("HTTP: Request finished after connect")
				_request_finished.emit(false)
				return

			if cancelled:
				print("HTTP: Cancelled")
				if file:
					file.close()
				cancelled = false
				http.close()
				_request_finished.emit(false)
				return

			if status == HTTPClient.STATUS_REQUESTING:
				http.poll()
				status = http.get_status()
				print("HTTP: Status changed to " + str(status))
				if status == HTTPClient.STATUS_BODY:
					response_code = http.get_response_code()
					var tmp_response_headers: Dictionary = http.get_response_headers_as_dictionary()
					response_headers.clear() 
					var s:String
					for key_ in tmp_response_headers:
						var key: String = key_
						var upper_key: String
						for key_part in key.split("-"):
							if not upper_key.is_empty():
								upper_key += "-"
							upper_key += key_part.substr(0, 1).to_upper() + key_part.substr(1).to_lower()
						if response_headers.has(upper_key):
							response_headers[upper_key] = response_headers[upper_key] + "," + tmp_response_headers[key]
						else:
							response_headers[upper_key] = tmp_response_headers[key]

					bytes = 0
					if response_headers.has("Content-Length"):
						total_bytes = int(response_headers["Content-Length"])
					else:
						total_bytes = -1
					self.download_progressed.emit(0, total_bytes)
					print("GOT PROGRESS " + str(out_path))
					if not out_path.is_empty():
						print(out_path)
						file = FileAccess.open(out_path, FileAccess.WRITE)
						if file == null:
							status = HTTPClient.STATUS_CONNECTED  # failed to write to file
							_request_finished.emit(false)
							return

			var last_yield = Time.get_ticks_msec()
			while status == HTTPClient.STATUS_BODY:
				print("HTTP: Status is " + str(status))
				var _poll_error: int = http.poll()

				var chunk: PackedByteArray = http.read_response_body_chunk()
				response_code = http.get_response_code()
				if adapt_godot_resource_header:
					# Binary resources start with RSRC or RSCC.
					# However, FileAccess.open_compressed requires files to start with GCPF
					# We also want to protect against resources being loaded before validation.
					# The first chunk must be at least 4 bytes.
					if len(chunk) < 4:
						chunk.append_array(http.read_response_body_chunk())
					if len(chunk) < 4:
						push_warning("HTTP Chunk should not be smaller than 4 bytes")
						cancelled = true
						return
					# RSRC (uncompressed) or RSCC (compressed)
					if chunk[0] != 'R'.unicode_at(0) or chunk[1] != 'S'.unicode_at(0) or (chunk[2] != 'R'.unicode_at(0) and chunk[2] != 'C'.unicode_at(0)) or chunk[3] != 'C'.unicode_at(0):
						# Not a Godot resource, even though a Godot resource was expected.
						cancelled = true
						return
					# Rewrite the header to say GRPF (uncompressed) or GCPF (compressed)
					# The validator will overwrite the header with RSRC or RSCC after validation.
					chunk[0] = 'G'.unicode_at(0) # G
					chunk[1] = chunk[2] # R or C
					chunk[2] = 'P'.unicode_at(0) # P
					chunk[3] = 'F'.unicode_at(0) # F
				
				if file:
					file.store_buffer(chunk)
				else:
					response_body.append_array(chunk)
				bytes += chunk.size()
				self.download_progressed.emit(bytes, total_bytes)

				var time = Time.get_ticks_msec()

				status = http.get_status()
				if status == HTTPClient.STATUS_CONNECTION_ERROR and !cancelled:
					print("HTTP: Got error " + str(status))
					if file:
						file.close()
					_request_finished.emit(false)
					return

				if status != HTTPClient.STATUS_BODY:
					print("HTTP: Finished body " + str(status))
					if file:
						file.flush()
						file.close()
					_request_finished.emit(true)

				if time - last_yield > YIELD_PERIOD_MS:
					print("HTTP: yield expired " + str(status) + " "  + str(time - last_yield))
					return

	func connect_http(hostname: String, port: int, use_ssl: bool) -> HTTPClient:
		sent_request = false
		status = http.get_status()
		var connection = http.connection
		if use_ssl and status == HTTPClient.STATUS_CONNECTED:
			if connection is StreamPeerTLS:
				var underlying: StreamPeer = connection.get_stream()
				if underlying is StreamPeerTCP:
					if status == HTTPClient.STATUS_CONNECTED and underlying.get_connected_host() == hostname and underlying.get_connected_port() == port:
						return http
				else:
					if status == HTTPClient.STATUS_CONNECTED:
						return http
		elif not use_ssl and status == HTTPClient.STATUS_CONNECTED:
			if connection is StreamPeerTCP:
				if (not (connection is StreamPeerTLS)) and status == HTTPClient.STATUS_CONNECTED and connection.get_connected_host() == hostname and connection.get_connected_port() == port:
					return http

		for i in range(3):
			var _poll_error: int = http.poll()
			status = http.get_status()
			if _poll_error != OK or (status != HTTPClient.STATUS_DISCONNECTED and status != HTTPClient.STATUS_CONNECTED):
				http.close()
				http = HTTPClient.new()

			if status != HTTPClient.STATUS_CONNECTED:
				var tls_options: TLSOptions = TLSOptions.client(null)
				print("Connect to " + str(hostname) + " : " + str(port) + " using ssl=" + str(use_ssl))
				connect_err = http.connect_to_host(hostname, port, tls_options if use_ssl else null)
				if connect_err != OK:
					printerr("HTTPPool: could not connect to host: returned error %s" % str(connect_err))
					http.close()
					http = HTTPClient.new()
					return null

			http_pool.http_tick.connect(self.http_tick)
			print("HTTP status was " + str(http.get_status()))
			http = await self._connection_finished
			http_pool.http_tick.disconnect(self.http_tick)
			if (http != null and http.get_status() == HTTPClient.STATUS_CONNECTED):
				print("HTTP status is now " + str(http.get_status()))
				break
			print("failed to connect " + str(http))
			http = HTTPClient.new()
		return http

	func wait_for_request():
		sent_request = true
		http_pool.http_tick.connect(self.http_tick)
		var ret = await self._request_finished
		return ret

	func release():
		if not http_pool:
			return
		#print("Do release")
		if http_pool.http_tick.is_connected(self.http_tick):
			http_pool.http_tick.disconnect(self.http_tick)
		if self.http_pool != null and self.http != null:
			#print("Release http")
			self.http_pool._release_client(self.http)
			self.http_pool = null
			self.http = null


func _process(_ts: float):
	http_tick.emit()


func _init(p_http_client_limit: int = 5):
	total_http_clients = p_http_client_limit

func _acquire_client() -> HTTPClient:
	if not http_client_pool.is_empty():
		return http_client_pool.pop_back()
	var f = Future.new()
	pending_requests[next_request] = f
	next_request += 1
	return await f.completed


func _release_client(http: HTTPClient):
	var pending_key: Variant = null
	for pr in pending_requests:
		pending_key = pr
	if typeof(pending_key) != TYPE_NIL:
		var f: Future = pending_requests[pending_key]
		pending_requests.erase(pending_key)
		f.completed.emit(http)
	else:
		http_client_pool.push_back(http)


func new_http_state() -> HTTPState:
	var http_client: HTTPClient = await _acquire_client()
	return HTTPState.new(self, http_client)

class HTTPDownloadRequest:
	extends RefCounted
	var uri: String
	var method: HTTPClient.Method
	var request_headers: PackedStringArray
	var request_body_raw: PackedByteArray
	var output_file_path: String
	var is_godot_resource: bool

	var response_buffer: PackedByteArray
	var response_code: int
	var response_headers: Dictionary
	var response_total_length: int
	var response_bytes_received: int

	var _cancelled: bool = false
	var connect_err: Error = OK
	var http_state: HTTPState
	var http_status: HTTPClient.Status = HTTPClient.STATUS_DISCONNECTED
	var http_pool: Object

	func _set_http_state(hstate: HTTPState):
		http_state = hstate
		http_state.download_progressed.connect(_download_progressed)

	func _clear_http_state():
		if http_state != null:
			http_state.download_progressed.disconnect(_download_progressed)
			http_state.release()
			http_state = null

	func _download_progressed(bytes, length):
		if bytes == 0:
			response_headers = http_state.response_headers
			response_total_length = length		
			response_code = http_state.response_code
		response_bytes_received = bytes

	func cancel():
		if not _cancelled:
			_cancelled = true
			if http_state:
				http_state.cancel()

	func perform():
		return await http_pool.perform_request_object(self)

	# data will be assigned only if success and output_file_path == ""
	#signal completed(success: bool)


func create_request_object(uri: String, method: HTTPClient.Method=HTTPClient.METHOD_GET):
	var hdr: HTTPDownloadRequest = HTTPDownloadRequest.new()
	hdr.http_pool = self
	hdr.uri = uri
	hdr.method = method
	return hdr
	
func perform_request_object(hdr: HTTPDownloadRequest) -> bool:
	var uri_parts: PackedStringArray = hdr.uri.split("/", true, 4)
	var is_secure: bool
	var port: int
	var host: String
	if uri_parts[0] == "http:":
		port = 80
		is_secure = false
	elif uri_parts[0] == "https:":
		port = 443
		is_secure = true
	else:
		return false
	if uri_parts[1] != "": # http:/XXX/ malformed
		return false
	if uri_parts[2].contains("@"): # HTTP Authentication unsupported.
		return false
	if uri_parts[2].contains(":"):
		var hostport_parts: PackedStringArray = uri_parts[2].split(":")
		port = int(hostport_parts[1])
		host = hostport_parts[0]
	else:
		host = uri_parts[2]
	hdr._set_http_state(await new_http_state())
	hdr.http_state.adapt_godot_resource_header = hdr.is_godot_resource
	hdr.http_state.set_output_path(hdr.output_file_path)
	if hdr._cancelled:
		hdr.connect_err = ERR_SKIP
		hdr._clear_http_state()
		return false
	var hclient: HTTPClient = await hdr.http_state.connect_http(host, port, is_secure)
	if hclient == null or hdr._cancelled:
		hdr.connect_err = hdr.http_state.connect_err
		hdr._clear_http_state()
		return false
	var req_err: Error = hclient.request_raw(hdr.method, "/" + uri_parts[3], hdr.request_headers, hdr.request_body_raw)
	
	if req_err != OK or hdr._cancelled:
		hdr.connect_err = req_err
		hdr._clear_http_state()
		return false
	if not await hdr.http_state.wait_for_request():
		hdr.http_status = hclient.get_status()
		hdr._clear_http_state()
		return false
	hdr.response_buffer = hdr.http_state.response_body
	hdr._clear_http_state()
	return true
