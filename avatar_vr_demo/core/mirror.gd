extends MeshInstance3D

@export var left_camera: Camera3D
@export var right_camera: Camera3D 
@export var origin: XROrigin3D
@export var leftvp: SubViewport  
@export var rightvp: SubViewport 

func _ready():
	RenderingServer.connect("frame_pre_draw", update_mirror)
	var m = get_surface_override_material(0)
	m.set("shader_parameter/textureL", leftvp.get_texture())
	m.set("shader_parameter/textureR", rightvp.get_texture())
	set_surface_override_material(0, m)
	
var nbasis: Basis = Basis()
var ibasis: Basis = Basis()
var w_scale: float = 0.0

func update_mirror() -> void:
	var mirror_size: Vector2 = GameManager.get_mirror_size()
	leftvp.size = mirror_size
	rightvp.size = mirror_size
	
	var interface: XRInterface = XRServer.primary_interface
	if(interface and interface.get_tracking_status() != XRInterface.XR_NOT_TRACKING):
		render_view(interface, 0, left_camera)
		render_view(interface, 1, right_camera)
		nbasis = global_transform.basis.orthonormalized()
		ibasis = nbasis.inverse()
		w_scale = global_transform.basis.x.length() 
		
func render_view(p_interface: XRInterface, p_view_index: int, p_cam: Camera3D) -> void:
	var tx: Transform3D = p_interface.get_transform_for_view(p_view_index, origin.global_transform)

	var p: Vector3 = ibasis * (tx.origin- global_transform.origin)
	p.z *= -1
	p_cam.global_transform.basis = Basis(-nbasis.x,nbasis.y, -nbasis.z)
	p_cam.global_transform.origin = global_transform.origin + nbasis*p
	p_cam.set_frustum(w_scale, Vector2(p.x,-p.y), abs(p.z), 10000)
