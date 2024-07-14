extends Node

const http_pool_class = preload("./http_pool.gd")
const download_manager_class = preload("./download_manager.gd")

# Must be assigned to use this provider.
var http_pool: http_pool_class
var request_headers: PackedStringArray # Authorization headers?

func can_handle(proto: String, uri: String) -> bool:
	return proto == "http" or proto == "https"

class DownloadRequest:
	extends download_manager_class.DownloadRequestBase

	var hdr: http_pool_class.HTTPDownloadRequest

	func _init(hdr_: http_pool_class.HTTPDownloadRequest):
		hdr = hdr_

	func cancel():
		hdr.cancel()

	func perform() -> bool:
		return await hdr.perform()

	func get_bytes_received() -> int:
		return hdr.response_bytes_received

	func get_total_length() -> int:
		return hdr.response_total_length

	func get_percentage() -> float:
		var content_length: int = hdr.get_response_bytes()
		return hdr.response_bytes_received

	func get_response_headers() -> Dictionary:
		return hdr.response_headers

	func get_content_type() -> String:
		return hdr.response_headers.get("Content-Type", "application/octet-stream")

	func is_permanent_failure() -> bool:
		# 4xx are permanent failures...
		#if hdr.response_headers.get("Cache-Control", "").find("no-cache") != -1:
		return hdr.response_code == 410 # Gone status can safely be cached.


func create_download_request(uri: String, output_file_path: String, is_godot_resource: bool) -> RefCounted:
	print(uri)
	var hdr: http_pool_class.HTTPDownloadRequest = http_pool.create_request_object(uri, HTTPClient.METHOD_GET)
	hdr.output_file_path = output_file_path
	hdr.is_godot_resource = is_godot_resource
	return DownloadRequest.new(hdr)
