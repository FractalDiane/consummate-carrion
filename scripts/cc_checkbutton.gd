extends Control

signal toggled(pressed)

onready var button := $CheckButton as CheckButton
onready var text := $Text as Label

onready var sound_hover := $SoundHover as AudioStreamPlayer
onready var sound_on := $SoundClickOn as AudioStreamPlayer
onready var sound_off := $SoundClickOff as AudioStreamPlayer

func is_cc_button_pressed() -> bool:
	return button.pressed


func set_cc_button_checked(checked: bool) -> void:
	button.set_pressed_no_signal(checked)
	text.text = "  ON" if checked else "OFF  "
	text.align = Label.ALIGN_LEFT if checked else Label.ALIGN_RIGHT


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	emit_signal("toggled", button_pressed)
	if button_pressed:
		sound_on.play()
	else:
		sound_off.play()
		
	text.text = "  ON" if button_pressed else "OFF  "
	text.align = Label.ALIGN_LEFT if button_pressed else Label.ALIGN_RIGHT


func _on_CheckButton_mouse_entered() -> void:
	button.grab_focus()


func _on_CheckButton_mouse_exited() -> void:
	button.release_focus()
	

func _on_CheckButton_focus_entered() -> void:
	sound_hover.play()
	modulate = Color("#ead692")


func _on_CheckButton_focus_exited() -> void:
	modulate = Color.white
