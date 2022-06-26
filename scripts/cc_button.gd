extends Button

export(bool) var is_small := false

onready var polygon := $Polygon2D as Polygon2D
onready var sound_hover := $SoundHover as AudioStreamPlayer
onready var sound_click := $SoundClick as AudioStreamPlayer

const COLOR_UNHOVER := Color.black
const COLOR_HOVER := Color.teal

func _ready() -> void:
	$Text.set_text(text)
	
#	var new_points := PoolVector2Array()
#	for point in polygon.polygon:
#		var new_point := Vector2(point.x + rand_range(-10, 10), point.y + rand_range(-10, 10))
#		new_points.push_back(new_point)
#
#	polygon.polygon = new_points
	
		


func _on_CCButton_mouse_entered() -> void:
	grab_focus()


func _on_CCButton_mouse_exited() -> void:
	release_focus()


func _on_CCButton_focus_entered() -> void:
	sound_hover.play()
	polygon.color = COLOR_HOVER


func _on_CCButton_focus_exited() -> void:
	polygon.color = COLOR_UNHOVER


func _on_CCButton_pressed() -> void:
	sound_click.play()
	$AnimationPlayer.play("click_small" if is_small else "click")
