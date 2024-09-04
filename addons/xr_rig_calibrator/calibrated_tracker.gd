@tool
extends Node3D

#@export_node_path("Node3D") var raw_tracker: NodePath:
	#set(value):
		#raw_tracker = value
		#raw_tracker_node = get_node_or_null(raw_tracker)
@export var raw_tracker_node: Node3D
@export_custom(PROPERTY_HINT_RANGE,"-3,3,0.01") var position_offset: Vector3
@export_custom(PROPERTY_HINT_RANGE,"-180,180,0.01,degrees") var rotation_euler_offset: Vector3
@export var relative_scale: float = 1.0

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	raw_tracker_node = get_node_or_null(raw_tracker)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if raw_tracker_node == null:
		visible = false
		return
	#var parent := get_parent_node_3d()
	#if parent == null:
		#return
	var quat_offset: Quaternion = Quaternion.from_euler(rotation_euler_offset)
	#print(raw_tracker_node.global_position)
	#print(position_offset)
	if not basis.is_finite():
		basis = Basis.IDENTITY
	#print(quat_offset)
	#print(raw_tracker_node.global_transform.basis.get_rotation_quaternion())
	#print(raw_tracker_node.global_rotation * position_offset)
	#print(raw_tracker_node.global_position + raw_tracker_node.global_transform * position_offset)
	var raw_tracker_transform := Transform3D.IDENTITY
	if not is_zero_approx(relative_scale):
		raw_tracker_transform = raw_tracker_transform.scaled_local(Vector3.ONE * relative_scale)
	if raw_tracker_node.get_parent_node_3d() != null:
		raw_tracker_transform = raw_tracker_node.get_parent_node_3d().global_transform * raw_tracker_transform
	raw_tracker_transform *= raw_tracker_node.transform.orthonormalized()
	#print(raw_tracker_transform * position_offset)
	#print(get_parent().global_transform.affine_inverse().basis.get_scale())
	#position = get_parent().global_transform.orthonormalized().inverse() * (raw_tracker_transform * position_offset)
	position = (raw_tracker_transform * position_offset)
	#print((raw_tracker_node.global_transform.basis.get_rotation_quaternion() * quat_offset).get_euler())
	global_transform = Transform3D(Basis(raw_tracker_node.global_transform.basis.get_rotation_quaternion() * quat_offset), position)
