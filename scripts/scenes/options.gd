extends Control

var options := ConfigFile.new()
var in_credits := false

onready var slider_sound := $OptionsList/VolumeSound/SliderSound as HSlider
onready var slider_music := $OptionsList/VolumeMusic/SliderMusic as HSlider
onready var checkbox_fullscreen := $OptionsList/Checkboxes/Fullscreen/ButtonFullscreen
onready var checkbox_reducemotion := $OptionsList/Checkboxes/ReduceMotion/ButtonMotion

onready var button_license := $Credits/ButtonLicense as Control

onready var number_sound := $OptionsList/VolumeSound/Value
onready var number_music := $OptionsList/VolumeMusic/Value

onready var value_sound := 100
onready var value_music := 100
onready var value_fullscreen := false
onready var value_reducemotion := false

func _ready() -> void:
	if get_tree().get_current_scene() == self:
		$LabelOptions.set_bbcode("[center][tornado radius=5]Options[/tornado][/center]")
		
	if OptionsManager.do_options_exist():
		var sound_value := OptionsManager.user_options.get_value("Options", "volume_sound", 100) as int
		slider_sound.value = float(sound_value) / 100.0
		number_sound.text = str(sound_value)
		
		var music_value := OptionsManager.user_options.get_value("Options", "volume_music", 100) as int
		slider_music.value = float(music_value) / 100.0
		number_music.text = str(music_value)
		
		checkbox_fullscreen.set_cc_button_checked(OptionsManager.user_options.get_value("Options", "fullscreen", false) as bool)
		checkbox_reducemotion.set_cc_button_checked(OptionsManager.user_options.get_value("Options", "reduce_motion", false) as bool)

	OptionsManager.connect("fullscreen_changed", self, "_on_fullscreen_changed")
	
	if OptionsManager.reduce_motion_enabled():
		$LabelOptions.set_bbcode("[center]Options[center]")
		$Credits/Title.set_bbcode("Consummate Carrion")
	
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next") or Input.is_action_just_pressed("ui_focus_prev"):
		if get_focus_owner() == null:
			if in_credits:
				button_license.grab_focus()
			else:
				slider_sound.grab_focus()


func _on_fullscreen_changed(fullscreen: bool) -> void:
	value_fullscreen = fullscreen
	checkbox_fullscreen.set_cc_button_checked(fullscreen)


func _on_SliderSound_value_changed(value: float) -> void:
	var to_int := int(value * 100)
	number_sound.text = str(to_int)
	value_sound = to_int
	update_options()


func _on_SliderMusic_value_changed(value: float) -> void:
	var to_int := int(value * 100)
	number_music.text = str(to_int)
	value_music = to_int
	update_options()
	
	
func _on_ButtonFullscreen_toggled(button_pressed: bool) -> void:
	value_fullscreen = button_pressed
	update_options()


func _on_ButtonMotion_toggled(button_pressed: bool) -> void:
	value_reducemotion = button_pressed
	update_options()
	
	$LabelOptions.set_bbcode("[center]Options[center]" if button_pressed else "[center][tornado radius=5]Options[/tornado][/center]")
	$Credits/Title.set_bbcode("Consummate Carrion" if button_pressed else "[tornado radius=5]Consummate Carrion[/tornado]")


func update_options() -> void:
	OptionsManager.update_options(value_sound, value_music, value_fullscreen, value_reducemotion)


func _on_ButtonCredits_pressed() -> void:
	get_focus_owner().release_focus()
	if OptionsManager.reduce_motion_enabled():
		$AnimationPlayer.play("to_credits")
		$AnimationPlayer.seek(1, true)
	else:
		$CanvasLayer/ClickBlock.show()
		_on_TimerCredits_timeout()
		in_credits = true
		
		#$TimerCredits.start()


func _on_ButtonBack_pressed() -> void:
	if OptionsManager.reduce_motion_enabled():
		get_tree().change_scene("res://scenes/title.tscn")
		OptionsManager.play_sound_click()
	else:
		$CanvasLayer/ClickBlock.show()
		var title := load("res://scenes/title.tscn").instance() as Control
		title.rect_position.y = 720
		get_tree().get_current_scene().add_child(title)
		$AnimationPlayer.play("to_title")


func _on_TimerCredits_timeout() -> void:
	$AnimationPlayer.play("to_credits")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	$CanvasLayer/ClickBlock.hide()
	if anim_name == "to_title":
		get_tree().change_scene("res://scenes/title.tscn")


func _on_ButtonBack2_pressed() -> void:
	get_focus_owner().release_focus()
	if OptionsManager.reduce_motion_enabled():
		$AnimationPlayer.play("from_credits")
		$AnimationPlayer.seek(1, true)
	else:
		$CanvasLayer/ClickBlock.show()
		$AnimationPlayer.play("from_credits")
		in_credits = false


func _on_ButtonLicense_pressed() -> void:
	var path := OS.get_executable_path().get_base_dir() + "/LICENSE_THIRDPARTY.txt"
	OS.shell_open(path)
