extends "./processing_task.gd"

const validator_manager_class = preload("./validator_manager.gd")
const validator_class = preload("./base_validator.gd")

var validator_manager: validator_manager_class
var validator: validator_class

var input_scene: PackedScene
var output_node: Node3D


func _init(validator_manager_: validator_manager_class, validator_: validator_class, input_: PackedScene):
	validator = validator_
	validator_manager = validator_manager_
	input_scene = input_


func _perform() -> bool:
	var result: Dictionary = validator_manager.sanitise_packed_scene(input_scene, validator)
	if result["result"]["code"] != validator_manager_class.ImporterResult.OK:
		return false
	var ps: PackedScene = result["packed_scene"] as PackedScene
	var result_node: Node = ps.instantiate()
	if result_node == null:
		return false
	if not (result_node is Node3D):
		return false
	output_node = result_node
	return true
	
