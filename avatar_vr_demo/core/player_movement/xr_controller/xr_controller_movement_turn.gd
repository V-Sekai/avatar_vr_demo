extends "xr_controller_movement_provider.gd"

const player_movement_turn_const = preload("res://avatar_vr_demo/core/player_movement/player_movement_turn.gd")

##
## Input action for movement direction
##
@export var input_action : String = "primary"

var _turn_movement_node: Node

func _process(_delta: float) -> void:
	if !_controller.get_is_active():
		return

	_turn_movement_node.input -= _controller.get_vector2(input_action).x

func _ready():
	super._ready()
	
	assert(_player_movement_controller)
	for child in _player_movement_controller.get_children():
		if child is player_movement_turn_const:
			_turn_movement_node = child
