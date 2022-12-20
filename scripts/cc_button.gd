extends Button

export(bool) var is_small := false

var spawned_shadow: Polygon2D = null

onready var polygon := $Polygon2D as Polygon2D
onready var polygon_shadow := $PolygonShadow as Control
onready var tween_shadow := $TweenShadow
onready var sound_hover := $SoundHover as AudioStreamPlayer
onready var sound_click := $SoundClick as AudioStreamPlayer

const COLOR_UNHOVER := Color.black
const COLOR_HOVER := Color.teal

func _ready() -> void:
	$Text.set_text(text)
	
	polygon_shadow.rect_pivot_offset = Vector2(46, 46) if is_small else Vector2(176, 32)
	polygon_shadow.rect_position = Vector2(-6, 0) if is_small else Vector2.ZERO
	
#	var new_points := PoolVector2Array()
#	for point in polygon.polygon:
#		var new_point := Vector2(point.x + rand_range(-10, 10), point.y + rand_range(-10, 10))
#		new_points.push_back(new_point)
#
#	polygon.polygon = new_points
	

func set_cc_button_enabled(enabled: bool) -> void:
	disabled = not enabled
	if enabled:
		$Polygon2D.color = Color.black
	else:
		$Polygon2D.color = Color(0.2, 0.2, 0.2)		


func _on_CCButton_mouse_entered() -> void:
	grab_focus()


func _on_CCButton_mouse_exited() -> void:
	release_focus()


func _on_CCButton_focus_entered() -> void:
	if not disabled:
		sound_hover.play()
		polygon.color = COLOR_HOVER


func _on_CCButton_focus_exited() -> void:
	if not disabled:
		polygon.color = COLOR_UNHOVER


func _on_CCButton_pressed() -> void:
	sound_click.play()
	
	spawned_shadow = polygon.duplicate()
	polygon_shadow.add_child(spawned_shadow)
	tween_shadow.remove_all()
	tween_shadow.interpolate_property(polygon_shadow, "rect_scale", Vector2.ONE, Vector2(2.0, 2.0), 1.0)
	tween_shadow.interpolate_property(polygon_shadow, "modulate:a", 1.0, 0.0, 1.0)
	tween_shadow.start()
	
	$AnimationPlayer.play("click_new")


func _on_TweenShadow_tween_all_completed() -> void:
	spawned_shadow.queue_free()
