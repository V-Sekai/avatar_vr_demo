@tool
extends Node3D

const calibrated_tracker_script := preload("./calibrated_tracker.gd")

@export var skel: Skeleton3D

@export var calibration: bool = false
@export var calibrate_once: bool = false
@export var override_xr_active: bool = true

@export var raw_tracker_root: Node3D
@export var raw_trackers: Array[Node3D]

const MAX_CALIBRATION_PAIR_DISTANCE := 1.234

signal tracker_disabled(tracker_node: calibrated_tracker_script)
signal tracker_changed(tracker_node: calibrated_tracker_script)
signal tracker_enabled(tracker_node: calibrated_tracker_script)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func find_raw_trackers() -> Dictionary:
	if skel == null:
		return {}
	if raw_tracker_root != null:
		var matched = 0
		for n in raw_trackers:
			if n.get_parent() == raw_tracker_root:
				matched += 1
		if matched != raw_tracker_root.get_child_count():
			raw_trackers.clear()
			for n in raw_tracker_root.get_children():
				if n is Node3D:
					raw_trackers.append(n)

	# exclude hands and head from whitelist for now. those are automatic.
	var connection_bones := PackedStringArray(["LeftFoot", "RightFoot", "Hips"])
	var connection_points: PackedVector3Array

	var connected_trackers: Dictionary # tracker -> bone
	var connected_tracked_bones: Dictionary # bone -> tracker

	for bone_name in connection_bones:
		connection_points.append(skel.global_transform * skel.get_bone_global_pose(skel.find_bone(bone_name)).origin)
	#print("find cal " + str(connection_points))

	for tracker in raw_trackers:
		if not tracker.visible:
			continue
		var builtin_bone_name: String = ""
		var xr_node := tracker as XRNode3D
		if xr_node != null:
			if not xr_node.get_is_active() and not override_xr_active:
				continue
			if xr_node.pose != &"default": # FIXME: Which pose is correct for hand position?
				continue
			match xr_node.tracker:
				&"left_hand":
					builtin_bone_name = "LeftHand"
				&"right_hand":
					builtin_bone_name = "RightHand"
				&"head":
					builtin_bone_name = "Head"
		var xr_camera = tracker as XRCamera3D
		if xr_camera:
			builtin_bone_name = "Head"
		if not builtin_bone_name.is_empty() and connected_tracked_bones.get(builtin_bone_name) == null:
			connected_trackers[tracker] = builtin_bone_name
			connected_tracked_bones[builtin_bone_name] = tracker

	# minimize distance(bone, tracker) for all combinations of bone, tracker.
	# then, apply the delta transform.
	#print(raw_trackers)
	#print(connected_trackers)
	for i in range(len(connection_points)):
		#print(connection_points)
		var min_dist_sq: float = -1.0
		var min_tracker: Node3D = null
		var min_bone_idx: int = -1
		for tracker in raw_trackers:
			if not tracker.visible:
				continue
			var xr_node := tracker as XRNode3D
			if xr_node != null:
				if not xr_node.get_is_active() and not override_xr_active:
					continue
			if connected_trackers.has(tracker):
				continue
			var pos = tracker.global_position
			for j in range(len(connection_points)):
				if connected_tracked_bones.has(connection_bones[j]):
					continue
				var point: Vector3 = connection_points[j]
				if point.distance_squared_to(pos) < min_dist_sq or min_dist_sq < 0:
					min_dist_sq = point.distance_squared_to(pos)
					min_tracker = tracker
					min_bone_idx = j
					#print("Found a bone " + str(connection_bones[min_bone_idx]) + " " + str(min_tracker) + " dist " + str(min_dist_sq))
		# Arbitrary threshold
		if min_dist_sq > MAX_CALIBRATION_PAIR_DISTANCE:
			#print("Min Distance sq = " + str(min_dist_sq))
			# TODO: Make 1 meter maximum distance customizable.
			continue
		if min_bone_idx < 0:
			#print("Break because no min_bone")
			break
		var min_bone: String = connection_bones[min_bone_idx]
		connected_trackers[min_tracker] = min_bone
		connected_tracked_bones[min_bone] = min_tracker

	return connected_tracked_bones

func calibrate() -> void:
	# Which bones are allowed? Answer: for now, whitelist 6pt in find_raw_trackers()
	# Calculate which trackers map to which skeleton points
	var connected_tracked_bones: Dictionary = find_raw_trackers() # bone -> tracker
	if connected_tracked_bones.is_empty():
		return

	# Then, map those to existing trackers (found / disconnected trackers)
	# Then, disable (did not delete) any found / disconnected that didn't match
	var existing_tracker_nodes_by_name: Dictionary
	for chld in get_children():
		var calibrated_tracker := chld as calibrated_tracker_script
		if calibrated_tracker and calibrated_tracker.visible and not connected_tracked_bones.has(calibrated_tracker.name):
			print("calibration_orchestrator: Disable child " + str(chld.name) + " " + str(calibrated_tracker))
			calibrated_tracker.visible = false
			tracker_disabled.emit(calibrated_tracker)
		elif connected_tracked_bones.has(chld.name):
			if calibrated_tracker:
				existing_tracker_nodes_by_name[chld.name] = calibrated_tracker
				calibrated_tracker.raw_tracker_node = null
				if not calibrated_tracker.visible:
					print("calibration_orchestrator: Existing child " + str(chld.name) + " " + str(calibrated_tracker))
					#print(connected_tracked_bones)
					#print(existing_tracker_nodes_by_name)
					calibrated_tracker.visible = true
			else:
				if not chld.name.begins_with("_"):
					chld.name = "_" + chld.name

	# Finally, add any new trackers we discovered.
	for tracked_bone in connected_tracked_bones:
		if not existing_tracker_nodes_by_name.has(tracked_bone):
			print(existing_tracker_nodes_by_name)
			# Add any new trackers.
			var chld3d := Marker3D.new()
			# Child node names should be based on the calibrated bone name (LeftFoot, Head)
			# (not the source tracker name such as VIVE_1234 or LeftController)
			chld3d.name = tracked_bone
			chld3d.set_script(calibrated_tracker_script)
			# TODO: Set default position?
			add_child(chld3d)
			chld3d.owner = self if owner == null else owner
			print("calibration_orchestrator: Add child " + str(tracked_bone) + " " + str(chld3d))
			#print(connected_tracked_bones)
			#print(existing_tracker_nodes_by_name)
			existing_tracker_nodes_by_name[tracked_bone] = chld3d
		var calibrated_tracker := existing_tracker_nodes_by_name[tracked_bone] as calibrated_tracker_script
		if calibrated_tracker.raw_tracker_node != connected_tracked_bones[tracked_bone]:
			var was_null: bool = calibrated_tracker.raw_tracker_node == null
			calibrated_tracker.raw_tracker_node = connected_tracked_bones[tracked_bone]
			if was_null:
				tracker_enabled.emit(calibrated_tracker)
			else:
				tracker_changed.emit(calibrated_tracker)


	for bone_name in existing_tracker_nodes_by_name:
		var calibrated_tracker := existing_tracker_nodes_by_name[bone_name] as calibrated_tracker_script
		if calibrated_tracker == null:
			continue
		var raw_tracker_node: Node3D = calibrated_tracker.raw_tracker_node
		if raw_tracker_node == null:
			continue

		var skel_bone_position: Transform3D = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone(bone_name)))

		var raw_tracker_transform := Transform3D.IDENTITY
		if raw_tracker_node.get_parent_node_3d() != null:
			raw_tracker_transform = raw_tracker_node.get_parent_node_3d().global_transform
		raw_tracker_transform *= raw_tracker_node.transform.orthonormalized()
		#print("calibration_orchestrator: tracker " + str(bone_name) + " pos " + str(raw_tracker_node.global_transform) + " and " + str(skel_bone_position.origin))
		calibrated_tracker.position_offset = raw_tracker_transform.affine_inverse() * skel_bone_position.origin
		#print("calibration_orchestrator: tracker " + str(bone_name) + " rot " + str(raw_tracker_node.global_transform.basis.get_rotation_quaternion()) + " and " + str(skel_bone_position.basis.get_rotation_quaternion()))
		var quat_offset: Quaternion = raw_tracker_node.global_transform.basis.get_rotation_quaternion().inverse() * skel_bone_position.basis.get_rotation_quaternion()
		calibrated_tracker.rotation_euler_offset = quat_offset.get_euler()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if calibration or calibrate_once:
		calibrate()
	if calibrate_once:
		calibrate_once = false
