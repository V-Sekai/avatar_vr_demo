extends Node

@onready var movement_controller = get_parent()

func get_xr_origin() -> XROrigin3D:
	return movement_controller.xr_origin
	
func get_xr_camera() -> XRCamera3D:
	return movement_controller.xr_camera
	
func get_player_controller() -> CharacterBody3D:
	return movement_controller.player_controller
