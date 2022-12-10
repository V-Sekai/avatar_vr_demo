extends Node

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var player_controller: CharacterBody3D = null
@export var xr_origin: XROrigin3D = null
@export var xr_camera: XRCamera3D = null

@export var position_interpolation: Node3D = null

func _physics_process(p_delta: float) -> void:
	for child in get_children():
		child.execute(p_delta)
		
	# Apply gravity
	if !player_controller.is_on_floor():
		player_controller.velocity += Vector3.DOWN * _gravity * p_delta
		
	player_controller.move_and_slide()
	position_interpolation.origin_offset = -player_controller.get_position_delta()
