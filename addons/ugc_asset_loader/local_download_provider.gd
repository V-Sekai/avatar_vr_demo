extends Node

const download_manager_class = preload("./download_manager.gd")

# Must be assigned to use this provider.
var request_headers: PackedStringArray # Authorization headers?

func can_handle(proto: String, uri: String) -> bool:
	return proto == "res"

class DownloadRequest:
	extends download_manager_class.DownloadRequestBase

	var uri: String
	var output_file_path: String
	var is_godot_resource: bool

	func _init(uri: String, output_file_path: String, is_godot_resource: bool):
		self.uri = uri
		self.output_file_path = output_file_path
		self.is_godot_resource = is_godot_resource

	func cancel():
		pass

	func perform() -> bool:
		var da := DirAccess.open("res://")
		if not da.file_exists(self.uri):
			return false
		da.copy(self.uri, self.output_file_path)
		return true

	func get_bytes_received() -> int:
		return 0

	func get_total_length() -> int:
		return 1

	func get_percentage() -> float:
		return 1.0

	func get_response_headers() -> Dictionary:
		return {}

	func get_content_type() -> String:
		return "application/octet-stream"

	func is_permanent_failure() -> bool:
		var da := DirAccess.open("res://")
		return not da.file_exists(self.uri)


func create_download_request(uri: String, output_file_path: String, is_godot_resource: bool) -> RefCounted:
	return DownloadRequest.new(uri, output_file_path, is_godot_resource)
