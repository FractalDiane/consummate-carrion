extends VBoxContainer

export(Texture) var texture_empty: Texture = null
export(Texture) var texture_filled: Texture = null

var filled := false

#func fill(player_name: String, you: bool) -> void:
#	$TextureRect.set_texture(texture_filled)
#	$You.set_visible(you)
#	filled = true
#
#func unfill() -> void:
#	$TextureRect.set_texture(texture_empty)
#	$Name.hide()
#	$You.hide()
#	filled = false
