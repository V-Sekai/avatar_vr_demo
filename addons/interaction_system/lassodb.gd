extends RefCounted

class PointOfInterest:
	extends RefCounted
	@export var snapping_power: float = 1.0
	@export var snapping_enabled: bool = true
	@export var snap_locked: bool = true
	@export var size: float = 0.3
	var last_snap_score: float = 0.0
	var db: WeakRef # LassoDB. Avoid reference cycle.
	var origin: Node3D

	func register_point(db_: RefCounted, origin_: Node):
		origin = origin_ as Node3D
		if not origin:
			return
		db = weakref(db_) as WeakRef
		db_.add_point(self)

	func unregister_point():
		var db_: RefCounted = db.get_ref()
		if db_:
			db_.remove_point(self)

	func get_origin_pos() -> Vector3:
		if origin:
			return origin.global_position
		return Vector3.ZERO

	func is_valid_origin() -> bool:
		return origin != null and origin.is_visible_in_tree() and snapping_enabled

	func is_matching_origin(p_origin: Node) -> bool:
		return origin == p_origin

# var points: Array[PointOfInterest]
#
var point_set: Dictionary

func add_point(point: PointOfInterest) -> void:
	if point and not point_set.has(point):
		# points.append(point)
		point_set[point] = true

func remove_point(point: PointOfInterest) -> void:
	# var idx: int = points.find(point)
	# if idx >= 0: points.remove_at(idx)
	point_set.erase(point)

func calc_top_two_snapping_power(source: Transform3D, current_snap: Node,
		snap_max_power_increase: float, snap_increase_amount: float, snap_lock: bool,
		min_snap_score: float) -> Array:
	var output: Array
	var first: PointOfInterest
	var second: PointOfInterest
	for pt in point_set:
		var next := pt as PointOfInterest
		if next and next.is_valid_origin() and next.snapping_enabled:
			var point_local: Vector3 = next.get_origin_pos() * source
			var euclidian_dist: float = point_local.length()
			var angular_dist: float = point_local.angle_to(Vector3(0, 0, -1))
			var rejection_length: float = Vector3(point_local[0], point_local[1], 0).length()

			var snapping_power: float = 0
			if rejection_length <= next.size:
				snapping_power = next.snapping_power / (1.0 + euclidian_dist) / (0.01 + angular_dist)
			else:
				snapping_power = next.snapping_power / (1.0 + euclidian_dist) / (0.1 + angular_dist)

			if next.is_matching_origin(current_snap):
				snapping_power += snapping_power * pow(snap_increase_amount, 2) * snap_max_power_increase
				if next.snap_locked and snap_lock:
					next.last_snap_score = snapping_power
					first = next;
					second = null
					break

			next.last_snap_score = snapping_power
			if next.last_snap_score < min_snap_score:
				continue

			if first == null or first.last_snap_score < next.last_snap_score:
				second = first;
				first = next;
			elif second == null || second.last_snap_score < next.last_snap_score:
				second = next

	output.push_back(first)
	output.push_back(second)
	return output


func calc_top_redirecting_power(snapped_origin: Node,
		viewpoint: Transform3D,
		redirection_direction: Vector2) -> Node:
	var snapped_origin_Node3D := snapped_origin as Node3D
	if snapped_origin_Node3D == null:
		return null

	var output: Node = snapped_origin_Node3D

	if not redirection_direction.is_zero_approx():
		# Caclculate the basis.
		var snapped_origin_position: Vector3 = snapped_origin_Node3D.global_position;
		var snapped_vector: Vector3 = viewpoint.origin - snapped_origin_position;
		var z_vector: Vector3 = snapped_vector.normalized()
		var up_vector: Vector3 = viewpoint.basis.y.normalized()
		var x_vector: Vector3 = z_vector.cross(up_vector).normalized()
		var y_vector: Vector3 = x_vector.cross(z_vector).normalized()
		var local_basis := Basis(x_vector, y_vector, z_vector)
		var first: PointOfInterest
		var redirect_power: float = INF # The lower is better.
		for pt in point_set:
			var next := pt as PointOfInterest
			var next_power: float = 0
			if next and next.is_valid_origin() and not next.is_matching_origin(snapped_origin_Node3D):
				var point_vector: Vector3 = viewpoint.origin - next.get_origin_pos()
				if point_vector.angle_to(snapped_vector) < PI / 4.0:
					var point_xyz: Vector3 = local_basis * point_vector
					var point_xy := Vector2(point_xyz[0], -point_xyz[1])

					if absf(redirection_direction.angle_to(point_xy)) >= PI / 2:
						continue
						# Keep the redirect power at infinity if the joystick is more than
						# 90 degrees away from the point.
					elif redirection_direction[0] == 0 && point_xy[1] != 0:
						# If you moved your joystick perfectly vertically calculating the
						# intersection of two lines breaks because of the y = mx + b
						# notation so instead let's calculate the y intercept of the line.
						var bisecting_slope: float = -point_xy[0] / point_xy[1] # Rotated 90 because it's the bisecting line.
						var bisecting_y: float = point_xy[1] / 2 # Y value when the bisecting line intersects the line to the point.
						# Squared just because. we're not actually calculating dist.
						next_power = pow(bisecting_slope * -(point_xy[0] / 2) + bisecting_y, 2)
					elif point_xy[1] == 0:
						# Point is on the x-axis which means the bisecting line would be
						# vertical and also undefined we calculate.
						var bisecting_x: float = point_xy[0] / 2;
						var slope: float = redirection_direction[1] / redirection_direction[0] # rise over run
						var intersect_x: float = bisecting_x;
						var intersect_y: float = bisecting_x * slope;
						next_power = pow(intersect_x, 2) + pow(intersect_y, 2) # squared euclidean distance
					else:
						# This is the most common case
						# equation taken from the internet.
						var a1: float = -point_xy[0] / point_xy[1]
						var c1: float = (1 - a1) * point_xy[0] / 2
						var a2: float = redirection_direction[1] / redirection_direction[0]
						var x_component: float = c1 / (a2 - a1)
						var y_component: float = (a2 * c1) / (a2 - a1)
						next_power = pow(x_component, 2) + pow(y_component, 2);

					if next_power < redirect_power:
						redirect_power = next_power;
						first = next;

		if first != null and first.is_valid_origin():
			output = first.origin

	return output;
