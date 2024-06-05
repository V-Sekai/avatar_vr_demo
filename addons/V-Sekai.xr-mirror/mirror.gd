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

func _process(_delta: float):
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

func get_mirror_size() -> Vector2:
	var interface = XRServer.primary_interface
	if(interface):
		return interface.get_render_target_size() * GameManager.mirror_resolution_scale
	else:
		return get_viewport().size * GameManager.mirror_resolution_scale

func update_mirror() -> void:
	var mirror_size: Vector2 = GameManager.get_mirror_size()
	# Letterbox along the bigger axis. Not sure why it's tied to the viewport size if in XR
	var aspect = global_transform.basis.y.length() / global_transform.basis.x.length()
	if aspect < mirror_size.y / mirror_size.x:
		mirror_size = Vector2(mirror_size.x / aspect, mirror_size.x)
	else:
		mirror_size = Vector2(mirror_size.x, mirror_size.x * aspect)
	leftvp.size = mirror_size
	rightvp.size = mirror_size
	
	var interface: XRInterface = XRServer.primary_interface
	if(interface and interface.get_tracking_status() != XRInterface.XR_NOT_TRACKING):
		render_view(interface, 0, left_camera)
		render_view(interface, 1, right_camera)
	else:
		var camera: Camera3D = get_viewport().get_camera_3d()
		render_view(camera, 0, left_camera)

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

func render_view(p_interface: Object, p_view_index: int, p_cam: Camera3D) -> void:
	var proj: Projection
	var tx: Transform3D
	if p_interface is XRInterface:
		proj = p_interface.get_projection_for_view(p_view_index, 1.0, abs(0.1), 10000)
		tx = p_interface.get_transform_for_view(p_view_index, origin.global_transform)
	elif p_interface is Camera3D:
		proj = p_interface.get_camera_projection()
		tx = p_interface.global_transform
	else:
		p_interface.crash()

	var global_transform_ortho := global_transform.orthonormalized()
	var p: Vector3 = global_transform_ortho.basis.inverse() * (tx.origin- global_transform.origin)

	var portal_relative_matrix: Transform3D
	# Examples of portals and mirror matrices.
	# portal_relative_matrix = Transform3D(Basis(Vector3(0,1,0), Time.get_ticks_msec() * 0.0001), Vector3(-0.3,0.2,-0.1)) # Spinning portal
	# portal_relative_matrix = Transform3D(Basis(Vector3(0,1,0),PI/8)) # Test portal with rotation

	# portal_relative_matrix = Transform3D(Basis.FLIP_Z * Basis.FLIP_X, Vector3(0.1,0.05,0.3)) # Flipped mirror with offset
	#portal_relative_matrix = Transform3D.IDENTITY # Passthrough (No effect)

	portal_relative_matrix = Transform3D.IDENTITY # Mirrors

	if use_screenspace:
		var my_plane: Plane
		my_plane = Plane(Vector3(0,0,-1),-2.0 * (global_transform_ortho.affine_inverse() * tx.origin).z)
		proj = oblique_near_plane(tx.affine_inverse() * global_transform_ortho * my_plane, proj)
		proj = proj * Projection(tx.affine_inverse() * global_transform_ortho * portal_relative_matrix * Transform3D(Basis.IDENTITY, p))
		p_cam.set("override_projection",  Projection(Transform3D.FLIP_X) * proj *  Projection(Transform3D.FLIP_X))

	if !use_screenspace:
		var px = Projection(Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO)
		p_cam.set("override_projection", px)

	p_cam.global_transform = global_transform_ortho * portal_relative_matrix * Transform3D(Basis.FLIP_Z * Basis.FLIP_X, p * Vector3(1,1,-1))
	p_cam.set_frustum(global_transform.basis.get_scale().y, Vector2(p.x,-p.y), abs(p.z), 10000)

	RenderingServer.camera_set_transform(p_cam.get_camera_rid(), p_cam.global_transform)
