extends Control

export(bool) var skip := true

func _ready() -> void:
	if skip and OS.has_feature("editor"):
		_on_AnimationPlayerTransition_animation_finished("")


func goto_title() -> void:
	var title := preload("res://scenes/title.tscn").instance() as Control
	title.rect_position.x = 1280
	get_tree().get_current_scene().add_child(title)
	$AnimationPlayerTransition.play("to_title")
	

func _on_AnimationPlayerTransition_animation_finished(_anim_name: String) -> void:
	get_tree().change_scene("res://scenes/title.tscn")
