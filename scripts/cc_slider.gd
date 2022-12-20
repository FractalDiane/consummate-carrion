extends HSlider

export(bool) var sound_on_change := true

onready var sound_hover := $SoundHover as AudioStreamPlayer
onready var sound_move := $SoundMove as AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_SliderSound_mouse_entered() -> void:
	grab_focus()


func _on_SliderSound_mouse_exited() -> void:
	release_focus()


func _on_SliderSound_focus_entered() -> void:
	sound_hover.play()


func _on_CCSlider_value_changed(_value: float) -> void:
	if sound_on_change:
		sound_move.play()
