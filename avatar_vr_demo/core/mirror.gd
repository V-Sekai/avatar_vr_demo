extends MeshInstance3D

@export var left_camera: Camera3D
@export var right_camera: Camera3D 
@export var origin: XROrigin3D
@export var leftvp: SubViewport  
@export var rightvp: SubViewport 

@export var use_screenspace: bool
@export var legacy_process_update: bool

func _ready():
	RenderingServer.connect("frame_pre_draw", frame_pre_draw)
	var m = get_surface_override_material(0)
	m.set("shader_parameter/use_screenspace", use_screenspace)
	m.set("shader_parameter/textureL", leftvp.get_texture())
	m.set("shader_parameter/textureR", rightvp.get_texture())
	set_surface_override_material(0, m)
	
var nbasis: Basis = Basis()
var ibasis: Basis = Basis()
var w_scale: float = 0.0

func _process(delta: float):
	var m = get_surface_override_material(0)
	if m != null:
		m.set("shader_parameter/use_screenspace", use_screenspace)
		set_surface_override_material(0, m)
	# if not updated from RenderingServer...
	if legacy_process_update:
		update_mirror()

func frame_pre_draw():
	if not legacy_process_update:
		update_mirror()

func update_mirror() -> void:
	var mirror_size: Vector2 = GameManager.get_mirror_size()
	leftvp.size = mirror_size
	rightvp.size = mirror_size
	
	var interface: XRInterface = XRServer.primary_interface
	if(interface and interface.get_tracking_status() != XRInterface.XR_NOT_TRACKING):
		nbasis = global_transform.basis.orthonormalized()
		ibasis = nbasis.inverse()
		w_scale = global_transform.basis.x.length()
		render_view(interface, 0, left_camera)
		render_view(interface, 1, right_camera)

func oblique_near_plane(clip_plane: Plane, matrix: Projection) -> Projection:
	# Based on the paper
	# Lengyel, Eric. “Oblique View Frustum Depth Projection and Clipping”.
	# Journal of Game Development, Vol. 1, No. 2 (2005), Charles River Media, pp. 5–16.

	# Calculate the clip-space corner point opposite the clipping plane
	# as (sgn(clipPlane.x), sgn(clipPlane.y), 1, 1) and
	# transform it into camera space by multiplying it
	# by the inverse of the projection matrix
	var q = Vector4(
		(sign(clip_plane.x) + matrix.z.x) / matrix.x.x,
		(sign(clip_plane.y) + matrix.z.y) / matrix.y.y,
		-1.0,
		(1.0 + matrix.z.z) / matrix.w.z)

	var clip_plane4 = Vector4(clip_plane.x, clip_plane.y, clip_plane.z, clip_plane.d)

	# Calculate the scaled plane vector
	var c: Vector4 = clip_plane4 * (2.0 / clip_plane4.dot(q))

	# Replace the third row of the projection matrix
	matrix.x.z = c.x - matrix.x.w
	matrix.y.z = c.y - matrix.y.w
	matrix.z.z = c.z - matrix.z.w
	matrix.w.z = c.w - matrix.w.w
	return matrix

func render_view(p_interface: XRInterface, p_view_index: int, p_cam: Camera3D) -> void:
	var proj: Projection = p_interface.get_projection_for_view(p_view_index, w_scale, abs(0.1), 10000)
	var tx: Transform3D = p_interface.get_transform_for_view(p_view_index, origin.global_transform)

	var p: Vector3 = ibasis * (tx.origin- global_transform.origin)

	var portal_relative_matrix: Transform3D
	# These are multiplied later by the mirror reflection
	
	# portal_relative_matrix = Transform3D(Basis.FLIP_Z * Basis.FLIP_X, Vector3(0.1,0.05,0.3))
	# portal_relative_matrix = Transform3D(Basis(Vector3(0,1,0), Time.get_ticks_msec() * 0.0001), Vector3(-0.3,0.2,-0.1))

	# portal_relative_matrix = Transform3D(Basis.FLIP_Z * Basis.FLIP_X) # Passthrough (No effect)
	portal_relative_matrix = Transform3D.IDENTITY # Mirror

	p.z *= -1
	#w_scale = lerp(p_interface.get_projection_for_view(0, 1.5, abs(p.z), 100).x.x, p_interface.get_projection_for_view(1, 1.5, abs(p.z), 100).x.x, 0.5)
	p_cam.global_transform = global_transform * portal_relative_matrix * Transform3D(Basis.FLIP_Z * Basis.FLIP_X, p)
	p_cam.set_frustum(w_scale, Vector2(p.x,-p.y), abs(p.z), 10000)
	RenderingServer.camera_set_transform(p_cam.get_camera_rid(), p_cam.global_transform)

	if not use_screenspace:
		var px = Projection(Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO)
		p_cam.set("override_projection", px)

	if use_screenspace:

		#print(Projection.create_frustum_aspect(w_scale, 1.0, Vector2(p.x, -p.y), abs(p.z), 10000))
		
		# WORKING pt 1:
		#print(-(get_transform().affine_inverse() * tx.origin).z)
		var my_plane: Plane
		my_plane = Plane(Vector3(0,0,-1),-2.0 * (get_transform().affine_inverse() * tx.origin).z)
		#print(my_plane)
		proj = oblique_near_plane(tx.affine_inverse() * get_transform() * my_plane, proj)
		proj = proj * Projection(tx.affine_inverse() * get_transform()) * Projection(portal_relative_matrix * Transform3D(Basis.FLIP_Z * Basis.FLIP_X)) * Projection(get_transform().affine_inverse() * p_cam.global_transform)
		p_cam.set("override_projection", proj)
		#print(p_cam.override_projection)

	# pt 2 bad:
	#proj = proj * Projection(tx.affine_inverse() * get_transform()) * Projection(Transform3D.FLIP_Z * Transform3D.FLIP_X) * Projection(get_transform().affine_inverse() * p_cam.global_transform)
	#proj = oblique_near_plane(p_cam.global_transform.affine_inverse() * get_transform() * Plane(Vector3(0,0,1),-10), proj)
	#p_cam.override_projection = proj
	
	#pt 3:
	#var c = oblique_near_plane_z_row_adjust(p_cam.global_transform.affine_inverse() * get_transform() * Plane(Vector3(0,0,-1),0), proj)
	#proj = proj * Projection(tx.affine_inverse() * get_transform()) * Projection(Transform3D.FLIP_Z * Transform3D.FLIP_X) * Projection(get_transform().affine_inverse() * p_cam.global_transform)
	#proj.x.z = c.x - proj.x.w
	#proj.y.z = c.y - proj.y.w
	#proj.z.z = c.z - proj.z.w
	#proj.w.z = c.w - proj.w.w
	#p_cam.override_projection = proj

	#p_cam.global_transform = tx
	#p_cam.override_projection = proj * Projection(get_transform() * Transform3D.FLIP_Z * get_transform().affine_inverse()) # * tx * p_cam.global_transform)
	#print(p_cam.global_transform)
	#print("-------")
