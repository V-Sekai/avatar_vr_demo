extends Node

var interface : XRInterface = null

var mirror_resolution_scale: float = 1.0

func get_mirror_size() -> Vector2:
	interface = XRServer.primary_interface
	if(interface):
		return interface.get_render_target_size() * mirror_resolution_scale
	else:
		return get_viewport().size * mirror_resolution_scale

func _ready() -> void:
	interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized():
		var vp : Viewport = get_viewport()
		vp.use_xr = ProjectSettings.get_setting("rendering/xr/enabled")
		
