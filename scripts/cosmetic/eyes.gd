extends Node2D

func _ready() -> void:
	randomize_timer()
	$Timer.start()

func randomize_timer() -> void:
	var time := rand_range(3.0, 8.0)
	$Timer.set_wait_time(time);
