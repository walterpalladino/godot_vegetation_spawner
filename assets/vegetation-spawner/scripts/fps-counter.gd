extends Node3D

@onready var start_counter_time = Time.get_ticks_usec()
var frames_count : float = 0
@export var time_between_calculation : float = 15000.0
var last_time_calculation : float = 0.0


@onready var lbl_fps : Label = get_node("SubViewportContainer/SubViewport/LblFPS")

func _process(delta: float) -> void:
	frames_count += 1.0
	if 	Time.get_ticks_msec() > last_time_calculation + time_between_calculation:
		last_time_calculation = Time.get_ticks_msec()
		print_debug(frames_count / (Time.get_ticks_usec() - start_counter_time) * 1000.0 * 1000.0)
	#print(lbl_fps)
	#lbl_fps.text = str(Engine.get_frames_per_second())
	lbl_fps.text = "FPS: " + str(Engine.get_frames_per_second())
