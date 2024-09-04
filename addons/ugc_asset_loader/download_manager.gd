extends Node

class DownloadProviderBase:

	func create_download_request(uri: String, output_file_path: String, is_godot_resource: bool) -> DownloadRequestBase:
		return null


# Example implementations:
class DownloadRequestBase:
	var node: Node

	func _init(node_: Node):
		node = node_

	func cancel():
		pass

	func perform() -> bool:
		await node.get_tree().process_frame
		return false

	func get_percentage() -> float:
		var content_length: int = get_content_length()
		var bytes_received: int = get_bytes_received()
		if bytes_received <= 0:
			return 0.0
		if content_length <= 0:
			const MAGIC_NUMBER: float = float(1000000)
			if bytes_received < MAGIC_NUMBER:
				return (50.0 * bytes_received) / MAGIC_NUMBER
			return 95.0 - 50.0 * exp(1 - bytes_received / MAGIC_NUMBER)
		return 100.0 * bytes_received / content_length

	func get_content_length() -> int:
		return -1

	func get_bytes_received() -> int:
		return 0

	func is_permanent_failure() -> bool:
		return false

	func get_response_headers() -> Dictionary:
		return {}

	func get_content_type() -> String:
		return "application/octet-stream"


var download_providers: Array #[DownloadProviderBase]


func add_provider(provider: Object):
	download_providers.append(provider)


func create_download_request(uri: String, output_file_path: String, is_godot_resource: bool) -> DownloadRequestBase:
	var colon: int = uri.find(":")
	var proto: String = uri.substr(0, colon)
	for provider in download_providers:
		if provider.can_handle(proto, uri):
			return provider.create_download_request(uri, output_file_path, is_godot_resource)
	return null
