extends RefCounted

var input_disk_path: String
var output_res_path: String

var output_resource: Object

var cancelled: bool = false


func _invoke_completed_deferred(success: bool):
	completed.emit(success)


func _run_single_item():
	var success: bool = false
	if not cancelled:
		success = _perform()
	_invoke_completed_deferred.call_deferred(success)


func _perform() -> bool:
	return false


signal completed(result: bool)


func wait_to_finish() -> bool:
	# Must be called within the same frame.
	return await self.completed


func cancel():
	cancelled = true

func get_percentage() -> float:
	return 0.0
