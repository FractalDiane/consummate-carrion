extends Control

export(bool) var skip := true

func _ready() -> void:
	if skip and OS.has_feature("editor"):
		_on_AnimationPlayerTransition_animation_finished("")


func goto_title() -> void:
	var title := preload("res://scenes/title.tscn").instance() as Control
	$NewScene.add_child(title)
	if OptionsManager.reduce_motion_enabled():
		$NewScene.modulate.a = 0.0
		$AnimationPlayerTransition.play("to_title_reducedmotion")
	else:
		title.rect_position.x = 1280
		$AnimationPlayerTransition.play("to_title")
	

func _on_AnimationPlayerTransition_animation_finished(_anim_name: String) -> void:
	get_tree().change_scene("res://scenes/title.tscn")
