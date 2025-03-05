extends Node

const lassodb_class := preload("./lassodb.gd")
const canvas_plane_class := preload("res://addons/canvas_plane/canvas_plane.gd")
const canvas_3d_anchor := preload("res://addons/canvas_plane/canvas_3d_anchor.gd")

var lasso_db: lassodb_class
var canvas_planes: Array[canvas_plane_class]

var cursor_screen: MeshInstance3D
var cursor_ray: MeshInstance3D

func _init():
	lasso_db = lassodb_class.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().set_meta(&"interaction_manager", self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	cursor_screen = get_node("Cursor")
	cursor_ray = get_node("Ray")

func _enter_tree() -> void:
	get_viewport().set_meta(&"interaction_manager", self)


func register_node_3d(node: Node3D):
	var lasso_point := lassodb_class.PointOfInterest.new()
	lasso_point.register_point(lasso_db, node)


func register_canvas(cp: canvas_plane_class):
	if cp.has_meta(&"canvas_registered"):
		return
	cp.set_meta(&"canvas_registered", true)
	var root_control: Control = cp.control_root
	var form_element: Control = root_control.find_next_valid_focus()
	var already_added_items := {}
	var canvas_anchors := root_control.find_children("*", "Node3D", false, false)
	print(canvas_anchors)
	for anchor in canvas_anchors:
		if anchor is canvas_3d_anchor:
			var canvas_item := anchor.get_node_or_null(anchor.canvas_item_node_path)
			anchor.canvas_item_node_path = NodePath("../" + str(cp.get_path_to(canvas_item)))
			anchor.reparent(cp)
	while form_element != null:
		print("New form element: " + str(form_element))
		already_added_items[form_element] = true
		# Get 3D position say way canvas 3d anchor works.
		var form_3d_anchor := canvas_3d_anchor.new()
		form_3d_anchor.canvas_item_node_path = NodePath("../" + str(cp.get_path_to(form_element)))
		cp.add_child(form_3d_anchor)
		# Add to LassoDB
		register_node_3d(form_3d_anchor)
		# Jump to next element
		var form_element_new: Control = form_element.find_next_valid_focus()
		if already_added_items.has(form_element_new):
			# Godot restarts at the beginning once we have found all focusable nodes.
			break
		form_element = form_element_new
	# TODO: Figure out how to maintain the list of form elements as they change.
	# TODO: figure out how to improve data structure
	# TODO: it might be nice to know if you are over a canvas and show a different mouse cursor or pointer.

var mouse_global_pos: Vector2

var last_coord: Vector2
var last_canvas_item: CanvasItem
var focused_control: Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func mouse_moved() -> void:
	#var position2D: Vector2 = get_viewport().get_mouse_position()
	var position2D: Vector2 = mouse_global_pos
	var camera: Camera3D = get_viewport().get_camera_3d()
	var dropPlane := camera.global_transform * Plane(Vector3(0, 0, -1), camera.near)
	var position3D := dropPlane.intersects_ray(
		camera.project_ray_origin(position2D),
		camera.project_ray_normal(position2D))
	#print(position3D)
	#print(camera.project_ray_origin(position2D))
	cursor_screen.global_position = position3D
	cursor_ray.scale = Vector3.ZERO
	var top_two = lasso_db.calc_top_two_snapping_power(
		Transform3D(Basis.looking_at(camera.project_ray_normal(position2D)), position3D),
		null, 0.01, 0.01, false, 0.5)
	var main_3d_anchor: canvas_3d_anchor = null
	if top_two[0] != null:
		main_3d_anchor = top_two[0].origin as canvas_3d_anchor
	if main_3d_anchor != null:
		if top_two[0] != null:
			var object_pos_2d := camera.unproject_position(main_3d_anchor.global_position)
			var object_pos_3d := dropPlane.intersects_ray(
				camera.project_ray_origin(object_pos_2d),
				camera.project_ray_normal(object_pos_2d))
			var log_score = clampf(log(2.0 * top_two[0].last_snap_score), 0, 1)
			#(get_child(0) as Node3D).global_position = position3D.lerp(
			#	object_pos_3d, (exp(log_score) - 1) / (exp(1) - 1))
			#if log_score < 1:
			#	main_3d_anchor = null
			cursor_ray.scale = Vector3(1, 1, position3D.distance_to(object_pos_3d))
			cursor_ray.position = position3D.lerp(object_pos_3d, 0.5)
			cursor_ray.look_at(object_pos_3d)
	if main_3d_anchor != null:
		var ci: CanvasItem = main_3d_anchor.canvas_item
		var viewport: Viewport
		if ci != null:
			viewport = ci.get_viewport()
		if ci != null and viewport != null:
			var center = ci.get_global_transform().origin
			var event := InputEventMouseMotion.new()
			event.set_global_position(center)
			event.set_relative(Vector2(0,0))  # should this be scaled/warped?
			event.set_button_mask(0)
			event.set_pressure(0.5)

			if viewport:
				viewport.push_input(event)
			if ci != last_canvas_item:
				var last_control := last_canvas_item as Control
				if last_control != null:
					#last_control.mouse_exited.emit()
					last_control.notify_thread_safe(Control.NOTIFICATION_MOUSE_EXIT)
				var new_control := ci as Control
				if new_control != null:
					#new_control.mouse_entered.emit()
					new_control.notify_thread_safe(Control.NOTIFICATION_MOUSE_ENTER)
					
			last_canvas_item = ci
			last_coord = center
	else:
		var last_control := last_canvas_item as Control
		if last_control != null:
			last_control.notify_thread_safe(Control.NOTIFICATION_MOUSE_EXIT)
			#last_control.mouse_exited.emit()
			last_canvas_item = null
		

var event_index: int = get_instance_id()


func handle_mouse_motion(global_pos: Vector2):
	mouse_global_pos = global_pos
	mouse_moved()

func handle_mouse_button(mb: InputEventMouseButton):
	var center = last_coord # last_canvas_item.get_global_transform().origin
	var ev := InputEventMouseButton.new()
	ev.set_global_position(center)
	#ev.set_relative(Vector2(0,0))  # should this be scaled/warped?
	ev.double_click = mb.double_click
	ev.factor = mb.factor
	ev.pressed = mb.pressed
	ev.canceled = mb.canceled
	ev.button_index = mb.button_index
	ev.set_button_mask(mb.button_mask)
	var new_button := last_canvas_item as BaseButton

	var new_control := last_canvas_item as Control
	if new_control != null:
		if focused_control != new_control:
			if focused_control != null:
				focused_control.notify_thread_safe(Control.NOTIFICATION_FOCUS_EXIT)
				#focused_control.focus_exited.emit()
			# new_control.notify_thread_safe(Control.NOTIFICATION_FOCUS_ENTER)
			new_control.grab_focus()
			new_control.grab_click_focus()
			#new_control.focus_entered.emit()
			focused_control = new_control
		var viewport = last_canvas_item.get_viewport()
		if viewport:
			# This doesn't seem to work...
			#viewport.push_input(ev)
			var ev2 := InputEventAction.new()
			ev2.action = &"ui_accept"
			ev2.pressed = mb.pressed
			ev2.event_index = event_index
			viewport.push_input(ev2)
		#ev.set_global_position(center)
		#ev.set_relative(Vector2(0,0))  # should this be scaled/warped?
		#ev.double_click = mb.double_click
		#ev.factor = mb.factor
		#ev.canceled = mb.canceled
		#ev.button_index = mb.button_index
		#ev.set_button_mask(mb.button_mask)

		#var new_button := last_canvas_item as BaseButton
		#if new_button != null:
			#new_button.button_pressed = ev.pressed
			#new_button.set_pressed_no_signal(ev.pressed)
			#new_button.pressed.emit()
			#new_button.shortcut_input
			#if ev.pressed:
				#print(InputMap.action_get_events(&"ui_accept"))
				#viewport.push_input(InputMap.action_get_events(&"ui_accept")[0])
	elif focused_control != null:
		focused_control.notify_thread_safe(Control.NOTIFICATION_FOCUS_EXIT)
		focused_control = null
		#focused_control.focus_exited.emit()


func _input(event: InputEvent):
	var me := event as InputEventMouseMotion
	if me != null:
		self.handle_mouse_motion(me.global_position)
	var mb := event as InputEventMouseButton
	if mb != null:
		self.handle_mouse_button(mb)
