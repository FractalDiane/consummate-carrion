extends Node

signal fullscreen_changed(fullscreen)

const OPTIONS_PATH := "user://options.cfg"
const SOUND_CLICK := preload("res://audio/sound/click2.ogg")

var user_options := ConfigFile.new()
var options_exist := false

func _ready() -> void:
	if user_options.load(OPTIONS_PATH) == OK:
		load_options()
		options_exist = true
		
		
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		var is_fullscreen := OS.is_window_fullscreen()
		update_options(
			user_options.get_value("Options", "volume_sound", 100),
			user_options.get_value("Options", "volume_music", 100),
			not is_fullscreen,
			user_options.get_value("Options", "reduce_motion", false)
		)
		
		emit_signal("fullscreen_changed", not is_fullscreen)
		
		
func do_options_exist() -> bool:
	return options_exist


func reduce_motion_enabled() -> bool:
	return user_options.get_value("Options", "reduce_motion", false) as bool
	
	
func play_sound_click() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = SOUND_CLICK
	player.volume_db = -4
	player.connect("finished", player, "queue_free")
	get_tree().get_root().add_child(player)
	player.play()


func update_options(volume_sound: int, volume_music: int, fullscreen: bool, reduce_motion: bool) -> void:
	user_options.set_value("Options", "volume_sound", volume_sound)
	AudioServer.set_bus_volume_db(0, linear2db(float(volume_sound) / 100.0))
	user_options.set_value("Options", "volume_music", volume_music)
	AudioServer.set_bus_volume_db(1, linear2db(float(volume_music) / 100.0))
	user_options.set_value("Options", "fullscreen", fullscreen)
	OS.set_window_fullscreen(fullscreen)
	user_options.set_value("Options", "reduce_motion", reduce_motion)
	
	user_options.save(OPTIONS_PATH)
	options_exist = true


func load_options() -> void:
	var volume_sound := user_options.get_value("Options", "volume_sound") as int
	AudioServer.set_bus_volume_db(0, linear2db(float(volume_sound) / 100.0))
		
	var volume_music := user_options.get_value("Options", "volume_music") as int
	AudioServer.set_bus_volume_db(1, linear2db(float(volume_music) / 100.0))
		
	var fullscreen := user_options.get_value("Options", "fullscreen") as bool
	OS.set_window_fullscreen(fullscreen)


static func remap(what: float, from1: float, to1: float, from2: float, to2: float) -> float:
	return (what - from1) / (to1 - from1) * (to2 - from2) + from2;
