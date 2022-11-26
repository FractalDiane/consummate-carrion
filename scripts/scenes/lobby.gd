extends Control

export(String, FILE, "*.tscn") var title_scene := String()
export(String, FILE, "*.tscn") var game_scene := String()

const LobbyPlayer := preload("res://prefabs/lobby_player.tscn")

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 12

const Themes := [
	"Trains",
	"Witchcraft",
	"Art",
	"Money",
	"Action Movie",
	"Nature",
	"Spies",
	"Video Games",
	"Music",
	"Underworld",
	"Transformation",
	"Amusement Park",
	"Comic Books",
	"Stunts",
	"Shopping",
	"Travel",
	"Horror",
	"Mystery",
	"Adventure",
	"Animals",
	"Dark Alley",
	"Imagination",
	"Dinner",
	"Royalty",
	"Fire",
	"Business",
	"Ninja",
	"Nature",
	"Photography",
	"Time Travel",
	"Superheroes",
	"Robots",
	"Computers",
	"Fashion",
	"Architecture",
	"Demons",
	"Sports",
]

onready var players_grid := $Players as GridContainer

onready var spinbox_timer := $Settings/HBoxContainer/SpinBoxTime as SpinBox
onready var spinbox_words := $Settings/HBoxContainer2/SpinBoxWords as SpinBox
onready var button_theme := $Settings/HBoxContainer3/CheckButtonTheme as CheckButton

var server_random_seed := 0


func _ready() -> void:
	$AnimationPlayer.play("init")
	var peer := NetworkedMultiplayerENet.new()
	NetworkManager.my_connection = peer
	get_tree().connect("connected_to_server", self, "finish_connecting", [peer])
	get_tree().connect("connection_failed", self, "connection_failed")
	get_tree().connect("server_disconnected", self, "connection_failed")
	if not NetworkManager.is_client:
		var result := peer.create_server(
			int(NetworkManager.client_port) if not NetworkManager.client_port.empty() else DEFAULT_PORT,
			 MAX_PLAYERS
		)
		
		if result != OK:
			connection_failed()
			return
			
		finish_connecting(peer)
	else:
		var result := peer.create_client(
			NetworkManager.client_ip if not NetworkManager.client_ip.empty() else DEFAULT_IP,
			int(NetworkManager.client_port) if not NetworkManager.client_port.empty() else DEFAULT_PORT,
			MAX_PLAYERS
		)
		
		if result != OK:
			connection_failed()
			return
			
		$TimerConnectTimeout.start()
	
	
func _on_TimerConnectTimeout_timeout() -> void:
	if NetworkManager.my_connection.get_connection_status() != NetworkedMultiplayerENet.CONNECTION_CONNECTED:
		connection_failed()
	
			
func finish_connecting(peer: NetworkedMultiplayerENet) -> void:
	get_tree().set_network_peer(peer)
	init_network_manager(NetworkManager.client_name)
	
	if get_tree().is_network_server():
		$SettingsBlocker.hide()
		$ButtonStart.show()
	
	NetworkManager.connect("player_connected", self, "_on_player_connected")
	NetworkManager.connect("player_disconnected", self, "_on_player_disconnected")
	if not get_tree().is_network_server():
		get_tree().connect("server_disconnected", self, "_on_server_disconnect")
	
	#$TimerAddMe.start()
	#call_deferred("add_player", NetworkManager.players[get_tree().get_network_unique_id()]["name"], true)
	
	$AnimationPlayer.play_backwards("transition")
	$SoundTransition2.play()
	$TimerAddMe.start()
	
	
func connection_failed() -> void:
	NetworkManager.my_connection = null
	NetworkManager.clear_players()
	NetworkManager.show_notification("Couldn't connect to the game at %s:%s." % [NetworkManager.client_ip, NetworkManager.client_port])
	get_tree().change_scene(title_scene)
	
	
	
func init_network_manager(my_name: String) -> void:
	NetworkManager.set_my_name(my_name)
	#NetworkManager.my_connection = peer
	NetworkManager.add_player(get_tree().get_network_unique_id())
	
		
func add_player(player_name: String, is_me: bool) -> void:
	var this_player := LobbyPlayer.instance() as VBoxContainer
	this_player.get_node("Name").set_text(player_name)
	if is_me:
		this_player.get_node("You").show()
	
	players_grid.add_child(this_player)
	
	if NetworkManager.get_player_count() >= 3:
		$ButtonStart.set_cc_button_enabled(true)


func remove_player(player_name: String) -> void:
	for player in players_grid.get_children():
		if player.get_node("Name").get_text() == player_name:
			player.queue_free()
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
	rpc("start_game_effects")
	
	
remotesync func start_game_effects() -> void:
	$SoundStart.play()
	$ClickBlock.show()
	$TimerStart.start()
	
	
remotesync func start_game() -> void:
	if get_tree().is_network_server():
		NetworkManager.randomize_player_order()
		NetworkManager.rpc("set_player_order", NetworkManager.player_order)
		
	get_tree().change_scene(game_scene)


func _on_ButtonExit_pressed() -> void:
	$ClickBlock.show()
	$TimerTransition.start()


func _on_TimerTransition_timeout() -> void:
	NetworkManager.title_transition = true
	$SoundTransition.play(0.25)
	$AnimationPlayer.play("transition")
	$TimerTitle.start()


func _on_TimerTitle_timeout() -> void:
	NetworkManager.my_connection.close_connection()
	NetworkManager.my_connection = null
	NetworkManager.clear_players()
	
	get_tree().change_scene(title_scene)


func _on_TimerStart_timeout() -> void:
	$SoundTransition.play(0.25)
	$AnimationPlayer.play("transition")
	$TimerStart2.start()


func _on_TimerStart2_timeout() -> void:
	if get_tree().is_network_server():
		rpc("start_game")


func _on_TimerAddMe_timeout() -> void:
	add_player(NetworkManager.players[get_tree().get_network_unique_id()]["name"], true)

