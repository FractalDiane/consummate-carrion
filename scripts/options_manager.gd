extends Node

const OPTIONS_PATH := "user://options.cfg"

var user_options := ConfigFile.new()
var options_exist := false

func _ready() -> void:
	if user_options.load(OPTIONS_PATH) == OK:
		load_options()
		options_exist = true
		
		
func do_options_exist() -> bool:
	return options_exist


func update_options(volume_sound: int, volume_music: int, fullscreen: bool, reduce_motion: bool) -> void:
	user_options.set_value("Options", "volume_sound", volume_sound)
	AudioServer.set_bus_volume_db(0, remap(volume_sound, 0, 100, -60, 4))
	user_options.set_value("Options", "volume_music", volume_music)
	AudioServer.set_bus_volume_db(1, remap(volume_music, 0, 100, -60, 4))
	user_options.set_value("Options", "fullscreen", fullscreen)
	OS.set_window_fullscreen(fullscreen)
	user_options.set_value("Options", "reduce_motion", reduce_motion)
	
	user_options.save(OPTIONS_PATH)
	options_exist = true


func load_options() -> void:
	var volume_sound := user_options.get_value("Options", "volume_sound") as int
	AudioServer.set_bus_volume_db(0, remap(volume_sound, 0, 100, -60, 4))
		
	var volume_music := user_options.get_value("Options", "volume_music") as int
	AudioServer.set_bus_volume_db(1, remap(volume_music, 0, 100, -60, 4))
		
	var fullscreen := user_options.get_value("Options", "fullscreen") as bool
	OS.set_window_fullscreen(fullscreen)


static func remap(what: float, from1: float, to1: float, from2: float, to2: float) -> float:
	return (what - from1) / (to1 - from1) * (to2 - from2) + from2;
