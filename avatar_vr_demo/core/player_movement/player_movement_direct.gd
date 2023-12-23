extends "player_movement_provider.gd"

@export var speed: float = 0.03

var input: Vector2 = Vector2()

func _get_action_rotation() -> Vector2:
	var overall_rotation: float = get_xr_origin().transform.basis.get_euler().y + get_xr_camera().transform.basis.get_euler().y
	var action_input: Vector2 = Vector2()
	
	action_input.y =- Input.get_action_strength("move_forwards") + Input.get_action_strength("move_backwards")
	action_input.x =- Input.get_action_strength("move_left") + Input.get_action_strength("move_right")

	action_input = action_input.normalized()
	
	var rotated_input = Vector2(
	action_input.y * sin(overall_rotation) + action_input.x * cos(overall_rotation),
	action_input.y * cos(overall_rotation) + action_input.x * -sin(overall_rotation))
	
	return rotated_input
	
func execute(_p_delta: float) -> void:
	var rotated_input = _get_action_rotation()
	
	rotated_input += input
	rotated_input = rotated_input.normalized()
	
	get_player_controller().velocity = Vector3(0.0, get_player_controller().velocity.y, 0.0) + (Vector3(rotated_input.x, 0.0, rotated_input.y) * speed) * Engine.physics_ticks_per_second

	# Reset the input
	input = Vector2()
