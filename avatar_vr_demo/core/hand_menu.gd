extends Control

@export var clock_label: Label
@export var fps_label: Label

func update_toolbar() -> void:
	var time_string: String = Time.get_time_string_from_system()
	clock_label.set_text(time_string)
	
	var fps: float = Engine.get_frames_per_second()
	fps_label.set_text("FPS: " + str(fps))

func _on_second_timer_timeout() -> void:
	update_toolbar()
	
func _ready() -> void:
	update_toolbar()
