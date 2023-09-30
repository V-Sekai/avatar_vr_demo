extends "player_movement_provider.gd"

@export var _velocity_accumulation = Vector3()
var _previous_camera_position = Vector2()

@export var update_rate: float = 0.1

@export var character_body: CharacterBody3D
	
func get_velocity_accumulation() -> Vector3:
	return _velocity_accumulation
	
func get_camera_position() -> Vector2:
	var camera_position_2d = Vector2(
		get_xr_camera().transform.origin.x,
		get_xr_camera().transform.origin.z
	)

	return camera_position_2d

func execute(_p_delta: float) -> void:
	if !character_body or !get_xr_origin() or !get_xr_camera():
		return
		
	# Store the character body velocity
	var previous_velocity: Vector3 = character_body.velocity
	
	# Get the xz offset between the camera and character controller
	var camera_position: Vector2 = get_camera_position()
	var camera_offset: Vector2 = (camera_position - _previous_camera_position).rotated(-get_xr_origin().basis.get_euler().y)
	
	# The velocity is the inverse of character_camera_offset multipled by physics FPS
	_velocity_accumulation += Vector3(
		camera_offset.x,
		0.0,
		camera_offset.y) * Engine.physics_ticks_per_second

	character_body.velocity = _velocity_accumulation
	
	var _did_collide: bool = character_body.move_and_slide()
	var distance_travelled: Vector3 = character_body.get_position_delta()
	
	# Apply the inverse to the origin
	get_xr_origin().transform.origin -= Vector3(distance_travelled.x, 0.0, distance_travelled.z)
	_velocity_accumulation -= Vector3(distance_travelled.x, 0.0, distance_travelled.z) * Engine.physics_ticks_per_second
	
	# Save camera position
	_previous_camera_position = camera_position

	# Reset the previous velocity
	character_body.velocity = previous_velocity
