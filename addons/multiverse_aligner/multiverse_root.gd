extends Node3D

@export var is_primary: bool = false

var viewport: Viewport
var world3d: World3D
var camera_node: Node3D

func _enter_tree() -> void:
	viewport = get_viewport()
	if viewport != null:
		print("Enter tree " + str(self) + " viewport " + str(viewport))
		viewport.set_meta(&"multiverse_root", self)

func _exit_tree() -> void:
	if viewport != null and viewport.get_meta(&"multiverse_root") == self:
		print("Exit tree " + str(self) + " viewport " + str(viewport))
		viewport.remove_meta(&"multiverse_root")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world3d = get_viewport().find_world_3d()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# print(str(self) + " IS " + str(is_primary) + " camera " + str(camera_node))
	if camera_node == null:
		return
	if is_primary:
		# print("PRIMARY")
		world3d.set_meta(&"multiverse_primary_camera", camera_node)
		return
	if not world3d.has_meta(&"multiverse_primary_camera"):
		return

	var primary_camera: Node3D = world3d.get_meta(&"multiverse_primary_camera")
	var primary_camera_xform: Transform3D = primary_camera.global_transform
	var this_relative_camera_xform: Transform3D = transform.affine_inverse() * camera_node.global_transform
	top_level = true
	transform = primary_camera_xform * this_relative_camera_xform
