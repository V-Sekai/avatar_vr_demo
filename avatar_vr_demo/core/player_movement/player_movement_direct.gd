extends "player_movement_provider.gd"

@export var speed: float = 0.03

var input: Vector2 = Vector2()

func execute(p_delta: float) -> void:
	var overall_rotation: float = get_xr_origin().transform.basis.get_euler().y + get_xr_camera().transform.basis.get_euler().y
	
	var rotated_velocity = Vector2(
	input.y * sin(overall_rotation) + input.x * cos(overall_rotation),
	input.y * cos(overall_rotation) + input.x * -sin(overall_rotation))
	
	get_player_controller().velocity = Vector3(0.0, get_player_controller().velocity.y, 0.0) + (Vector3(rotated_velocity.x, 0.0, rotated_velocity.y) * speed) * Engine.physics_ticks_per_second

	# Reset the input
	input = Vector2()
