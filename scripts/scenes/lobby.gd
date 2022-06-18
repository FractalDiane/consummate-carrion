extends Control

export(String, FILE, "*.tscn") var title_scene := String()
export(String, FILE, "*.tscn") var game_scene := String()

const LobbyPlayer := preload("res://prefabs/lobby_player.tscn")

onready var players_grid := $Players as GridContainer

onready var spinbox_timer := $Settings/HBoxContainer/SpinBoxTime as SpinBox
onready var spinbox_words := $Settings/HBoxContainer2/SpinBoxWords as SpinBox
onready var button_theme := $Settings/HBoxContainer3/CheckButtonTheme as CheckButton

var server_random_seed := 0


func _ready() -> void:
	if get_tree().is_network_server():
		$SettingsBlocker.hide()
		$ButtonStart.show()
		
		randomize()
		
	add_player(NetworkManager.players[get_tree().get_network_unique_id()]["name"], true)
	NetworkManager.connect("player_connected", self, "_on_player_connected")
	NetworkManager.connect("player_disconnected", self, "_on_player_disconnected")
	if not get_tree().is_network_server():
		get_tree().connect("server_disconnected", self, "_on_server_disconnect")
		
		
func add_player(player_name: String, is_me: bool) -> void:
	var this_player := LobbyPlayer.instance() as VBoxContainer
	this_player.get_node("Name").set_text(player_name)
	if is_me:
		this_player.get_node("You").show()
	
	players_grid.add_child(this_player)
	
	if NetworkManager.get_player_count() >= 3:
		$ButtonStart.set_disabled(false)


func remove_player(player_name: String) -> void:
	for player in players_grid.get_children():
		if player.get_node("Name").get_text() == player_name:
			players_grid.remove_child(player)
			break
			
	if NetworkManager.get_player_count() < 3:
		$ButtonStart.set_disabled(true)
		
sync func sync_setting_displays(time: float, words: float, show_theme: bool) -> void:
	spinbox_timer.set_value(time)
	spinbox_words.set_value(words)
	button_theme.set_pressed(show_theme)


func _on_SpinBoxTime_value_changed(value: float) -> void:
	NetworkManager.rpc("set_timer_max", int(value))
	rpc("sync_setting_displays", spinbox_timer.get_value(), spinbox_words.get_value(), button_theme.is_pressed())
	
	
func _on_SpinBoxWords_value_changed(value: float) -> void:
	NetworkManager.rpc("set_peek_words", int(value))
	rpc("sync_setting_displays", spinbox_timer.get_value(), spinbox_words.get_value(), button_theme.is_pressed())
	
	
func _on_CheckButtonTheme_toggled(button_pressed: bool) -> void:
	NetworkManager.rpc("set_show_theme", button_pressed)
	rpc("sync_setting_displays", spinbox_timer.get_value(), spinbox_words.get_value(), button_theme.is_pressed())
	
	
func _on_player_connected(id: int) -> void:
	add_player(NetworkManager.players[id]["name"], false)
	
	
func _on_player_disconnected(_id: int, player_name: String) -> void:
	remove_player(player_name)
	
	
func _on_server_disconnect() -> void:
	NetworkManager.my_connection = null
	NetworkManager.clear_players()
	get_tree().change_scene(title_scene)
	
	
func _on_ButtonStart_pressed() -> void:
	rpc("start_game")
	
	
remotesync func start_game() -> void:
	if get_tree().is_network_server():
		NetworkManager.randomize_player_order()
		NetworkManager.rpc("set_player_order", NetworkManager.player_order)
		
	get_tree().change_scene(game_scene)


func _on_ButtonExit_pressed() -> void:
	NetworkManager.my_connection.close_connection()
	NetworkManager.my_connection = null
	NetworkManager.clear_players()
	get_tree().change_scene(title_scene)
