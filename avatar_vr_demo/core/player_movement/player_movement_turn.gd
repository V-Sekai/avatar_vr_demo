extends "player_movement_provider.gd"

var input: float = 0.0
@export var free_turn_rate: float = 1.0

@export var rotation_interpolation: Node = null

func execute(p_delta: float) -> void:
	input = input + (Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right"))
	input = clampf(input, -1.0, 1.0)
	
	var rot_offset: float = input * free_turn_rate * p_delta
	
	var camera_position_2d: Vector3 = get_xr_camera().transform.origin
	camera_position_2d.y = 0.0
		
	var camera_position_transform: Transform3D = Transform3D(Basis(), camera_position_2d)
	get_xr_origin().transform = get_xr_origin().transform * camera_position_transform * Transform3D(Basis().rotated(Vector3.UP, rot_offset), Vector3()) * camera_position_transform.inverse()

	rotation_interpolation.rotation_offset = -rot_offset

	# Reset the input
	input = 0.0
