extends Spatial

export(ShaderMaterial) var material: ShaderMaterial = null

func set_screen_texture(texture: Texture) -> void:
	material.set_shader_param("screen_texture", texture)

func play_transition_animation() -> void:
	$AnimationPlayer.play("transition")
