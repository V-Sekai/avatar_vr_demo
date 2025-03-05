extends Node3D

const metaverse_root := preload("./multiverse_root.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	'''
	var x: Node3D = get_parent() as Node3D
	while x != null:
		if x is Node3D and x.get_script() == metaverse_root:
			x.camera_node = self
			break
		x = x.get_parent() as Node3D
	'''
	self.after_ready.call_deferred()

func after_ready():
	var vp: Viewport = get_viewport()
	print(vp)
	if vp != null and vp.has_meta(&"multiverse_root"):
		print("SET ROOT " + str(vp.get_meta(&"multiverse_root")) + str(vp.get_meta(&"multiverse_root").is_primary))
		vp.get_meta(&"multiverse_root").camera_node = self
