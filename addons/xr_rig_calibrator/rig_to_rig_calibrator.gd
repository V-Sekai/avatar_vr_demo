@tool
extends Node3D

const calibrated_tracker_script := preload("./calibrated_tracker.gd")

@export var source_skel: Skeleton3D
@export var target_skel: Skeleton3D

@export var lock_calibration: bool

@export var src_tracker_root: Node3D
@export var src_trackers: Array[Node3D]

var src_trackers_by_name: Dictionary
var src_trackers_to_name: Dictionary

const MAX_CALIBRATION_PAIR_DISTANCE := 1.234

signal tracker_disabled(tracker_node: calibrated_tracker_script)
signal tracker_changed(tracker_node: calibrated_tracker_script)
signal tracker_enabled(tracker_node: calibrated_tracker_script)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func find_src_trackers() -> void:
	src_trackers_by_name.clear()
	src_trackers_to_name.clear()
	if source_skel == null or target_skel == null:
		return
	if src_tracker_root != null:
		var matched = 0
		for n in src_trackers:
			if n.get_parent() == src_tracker_root:
				matched += 1
		if matched != src_tracker_root.get_child_count():
			src_trackers.clear()
			for n in src_tracker_root.get_children():
				if n is Node3D:
					src_trackers.append(n)
	for n in src_trackers:
		if target_skel.find_bone(n.name) == -1 and not source_skel.find_bone(n.name) == -1:
			continue
		if n.visible:
			src_trackers_by_name[n.name] = n
			src_trackers_to_name[n] = n.name


func calibrate() -> void:
	# Which bones are allowed? Answer: for now, whitelist 6pt in find_src_trackers()
	# Calculate which trackers map to which skeleton points
	find_src_trackers() # bone -> tracker
	if src_trackers_by_name.is_empty():
		return

	# Then, map those to existing trackers (found / disconnected trackers)
	# Then, disable (did not delete) any found / disconnected that didn't match
	var existing_tracker_nodes_by_name: Dictionary
	for chld in get_children():
		var calibrated_tracker := chld as calibrated_tracker_script
		if calibrated_tracker and calibrated_tracker.visible and not src_trackers_by_name.has(calibrated_tracker.name):
			print("calibration_orchestrator: Disable child " + str(chld.name) + " " + str(calibrated_tracker))
			calibrated_tracker.visible = false
			tracker_disabled.emit(calibrated_tracker)
		elif src_trackers_by_name.has(chld.name):
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
	for tracked_bone in src_trackers_by_name:
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
		if calibrated_tracker.raw_tracker_node != src_trackers_by_name[tracked_bone]:
			var was_null: bool = calibrated_tracker.raw_tracker_node == null
			calibrated_tracker.raw_tracker_node = src_trackers_by_name[tracked_bone]
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

		var src_skel_bone_rest: Transform3D = (source_skel.global_transform.orthonormalized() * (source_skel.get_bone_global_rest(source_skel.find_bone(bone_name))).scaled(Vector3.ONE * 1.0 / source_skel.motion_scale))
		var dst_skel_bone_rest: Transform3D = (target_skel.global_transform.orthonormalized() * (target_skel.get_bone_global_rest(target_skel.find_bone(bone_name))).scaled(Vector3.ONE * 1.0 / target_skel.motion_scale))

		#print("calibration_orchestrator: tracker " + str(bone_name) + " pos " + str(raw_tracker_node.global_transform) + " and " + str(skel_bone_position.origin))
		calibrated_tracker.position_offset = dst_skel_bone_rest.affine_inverse() * src_skel_bone_rest.origin
		#print("calibration_orchestrator: tracker " + str(bone_name) + " rot " + str(raw_tracker_node.global_transform.basis.get_rotation_quaternion()) + " and " + str(skel_bone_position.basis.get_rotation_quaternion()))
		var quat_offset: Quaternion = dst_skel_bone_rest.basis.get_rotation_quaternion().inverse() * src_skel_bone_rest.basis.get_rotation_quaternion()
		calibrated_tracker.rotation_euler_offset = quat_offset.get_euler()
		calibrated_tracker.relative_scale = 1.0 # sqrt(target_skel.motion_scale / source_skel.motion_scale)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not lock_calibration:
		calibrate()
