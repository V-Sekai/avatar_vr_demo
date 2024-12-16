@tool
extends Node

var avatar: Node3D
var avatar_skeleton: Skeleton3D
var player: Node3D

var renik: RenIK3D
var renik_foot_placement: RenIKPlacement3D


var ik_target_controller: Node3D
var xr_tracking_scaler: Node3D

# signal tracker_disabled(tracker_node)
# signal tracker_changed(tracker_node)
# signal tracker_enabled(tracker_node)

func _exit_tree() -> void:
	if renik != null:
		renik.armature_head_target = NodePath()
		renik.armature_left_hand_target = NodePath()
		renik.armature_right_hand_target = NodePath()
		renik.armature_hip_target = NodePath()
		renik.armature_left_foot_target = NodePath()
		renik.armature_right_foot_target = NodePath()
		renik.live_preview = false
		renik.armature_skeleton_path = NodePath()
	if renik_foot_placement != null:
		renik_foot_placement.armature_head_target = NodePath()
		renik_foot_placement.armature_hip_target = NodePath()
		renik_foot_placement.armature_left_foot_target = NodePath()
		renik_foot_placement.armature_right_foot_target = NodePath()
		renik_foot_placement.enable_hip_placement = false
		renik_foot_placement.enable_left_foot_placement = false
		renik_foot_placement.enable_right_foot_placement = false
		renik_foot_placement.live_preview = false
		renik_foot_placement.armature_skeleton_path = NodePath()

	

# Called when the node enters the scene tree for the first time.
func _ready():
	request_ready() # Ensdure _ready is called each time we are reparented!
	#renik = RenIK3D.new()
	#add_child(renik)
	avatar = get_parent() as Node3D
	avatar_skeleton = avatar.get_node("%GeneralSkeleton") if avatar != null else null
	if avatar_skeleton == null and avatar != null:
		# HACK since one of the files I am testing with wasn't imported correctly.
		avatar_skeleton = avatar.get_node("Skeleton3D")
	player = avatar.get_parent() if avatar != null else avatar

	renik = get_node_or_null("RenIK")
	renik_foot_placement = get_node_or_null("RenIKFootPlacement")


	if renik != null:
		renik.armature_head_target = NodePath()
		renik.armature_left_hand_target = NodePath()
		renik.armature_right_hand_target = NodePath()
		renik.armature_hip_target = NodePath()
		renik.armature_left_foot_target = NodePath()
		renik.armature_right_foot_target = NodePath()
		renik.live_preview = true
		renik.armature_skeleton_path = renik.get_path_to(avatar_skeleton)
	if renik_foot_placement != null:
		renik_foot_placement.armature_head_target = NodePath()
		renik_foot_placement.armature_hip_target = NodePath()
		renik_foot_placement.armature_left_foot_target = NodePath()
		renik_foot_placement.armature_right_foot_target = NodePath()
		renik_foot_placement.enable_hip_placement = false
		renik_foot_placement.enable_left_foot_placement = false
		renik_foot_placement.enable_right_foot_placement = false
		renik_foot_placement.live_preview = true
		renik_foot_placement.armature_skeleton_path = renik_foot_placement.get_path_to(avatar_skeleton)

	#var player_node_path: NodePath = NodePath("../..")
	#renik.armature_head_target = NodePath(str(player_node_path) + "/" + str(player.get_head_target()))
	#renik.armature_left_hand_target = NodePath(str(player_node_path) + "/" + str(player.get_left_hand_target()))
	#renik.armature_right_hand_target = NodePath(str(player_node_path) + "/" + str(player.get_right_hand_target()))
	if player != null:
		ik_target_controller = player.get_node_or_null("IKTargets")
		xr_tracking_scaler = player.get_node_or_null("XRTrackingScaler")
	if xr_tracking_scaler != null:
		xr_tracking_scaler.target_skel = avatar_skeleton
	if ik_target_controller != null:
		var required_ik := {&"Hips": true, &"Head": true, &"LeftFoot": true, &"RightFoot": true}
		# ik_target_controller.connect(&"tracker_changed", _tracker_changed)
		xr_tracking_scaler.target_skel = avatar_skeleton
		ik_target_controller.connect(&"tracker_disabled", _tracker_disabled)
		ik_target_controller.connect(&"tracker_enabled", _tracker_enabled)
		for child in ik_target_controller.get_children():
			if child.visible:
				_tracker_enabled(child)
			else:
				_tracker_disabled(child)
			if required_ik.has(child.name):
				required_ik.erase(child.name)
		for child_name in required_ik:
			_tracker_disabled_by_name(child_name)
		renik.set_process_internal(true)
		renik_foot_placement.set_process_internal(true)
		renik_foot_placement.set_physics_process_internal(true)

func _tracker_disabled(tracker: Node3D):
	var foot_placement_node: Node3D = _tracker_disabled_by_name(tracker.name)
	if foot_placement_node != null:
		foot_placement_node.global_transform = tracker.global_transform

func _tracker_disabled_by_name (tracker_name: StringName) -> Node3D:
	var renik_property: StringName
	if renik == null or renik_foot_placement == null:
		return
	match tracker_name:
		&"Hips":
			renik_property = &"armature_hip_target"
			renik_foot_placement.enable_hip_placement = true
		&"LeftFoot":
			renik_property = &"armature_left_foot_target"
			renik_foot_placement.enable_left_foot_placement = true
		&"RightFoot":
			renik_property = &"armature_right_foot_target"
			renik_foot_placement.enable_right_foot_placement = true
	if renik_property == StringName():
		return
	var foot_placement_node := renik_foot_placement.get_node_or_null(NodePath(tracker_name)) as Node3D
	if foot_placement_node == null:
		foot_placement_node = Node3D.new()
		foot_placement_node.name = tracker_name
		renik_foot_placement.add_child(foot_placement_node)
		foot_placement_node.owner = self.owner
	renik.set(renik_property, NodePath("../RenIKFootPlacement/" + tracker_name))
	renik_foot_placement.set(renik_property, NodePath("../RenIKFootPlacement/" + tracker_name))
	return foot_placement_node
	

func _tracker_enabled(tracker: Node3D):
	var renik_property: StringName
	if renik == null:
		return
	match tracker.name:
		&"Head":
			renik_property = &"armature_head_target"
			if renik_foot_placement != null:
				renik_foot_placement.set(renik_property, renik_foot_placement.get_path_to(tracker))
		&"Hips":
			renik_property = &"armature_hip_target"
			if renik_foot_placement != null:
				renik_foot_placement.set(renik_property, NodePath())
				renik_foot_placement.enable_hip_placement = false
		&"LeftFoot":
			renik_property = &"armature_left_foot_target"
			if renik_foot_placement != null:
				renik_foot_placement.set(renik_property, NodePath())
				renik_foot_placement.enable_left_foot_placement = false
		&"RightFoot":
			renik_property = &"armature_right_foot_target"
			if renik_foot_placement != null:
				renik_foot_placement.set(renik_property, NodePath())
				renik_foot_placement.enable_right_foot_placement = false
		&"LeftHand":
			renik_property = &"armature_left_hand_target"
		&"RightHand":
			renik_property = &"armature_right_hand_target"
	if renik_property == StringName():
		return
	renik.set(renik_property, renik.get_path_to(tracker))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
