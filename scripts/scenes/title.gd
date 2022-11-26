extends Control

export(String, FILE, "*.tscn") var game_scene := String()

const LobbyPlayer := preload("res://prefabs/lobby_player.tscn")

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 12

var transition_to_lobby := false

onready var edit_name := $TitleScreen/EditName as LineEdit
onready var edit_join_ip := $TitleScreen/EditJoinIp as LineEdit
onready var edit_join_port := $TitleScreen/EditJoinPort as LineEdit
onready var edit_host_port := $TitleScreen/EditHostPort as LineEdit

onready var players_grid := $Lobby/Players as GridContainer
onready var spinbox_timer := $Lobby/Settings/HBoxContainer/SpinBoxTime as SpinBox
onready var spinbox_words := $Lobby/Settings/HBoxContainer2/SpinBoxWords as SpinBox
onready var button_theme := $Lobby/Settings/HBoxContainer3/CheckButtonTheme as CheckButton

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
	"Camping",
]


func _ready() -> void:
	$TitleScreen/ButtonHost.set_cc_button_enabled(false)
	$TitleScreen/ButtonJoin.set_cc_button_enabled(false)
	$Lobby/ButtonStart.set_cc_button_enabled(false)
	#$AnimationPlayer.play_backwards("transition")
	#if NetworkManager.title_transition:
	#	$SoundTransition2.play()
	#	NetworkManager.title_transition = false

	#NetworkManager.show_notification("HELLO THIS IS A NOTIFICATION YEAH")

# TITLE SCREEN ====================================================================================

func _on_EditName_text_changed(new_text: String) -> void:
	$TitleScreen/ButtonHost.set_cc_button_enabled(not new_text.empty())
	$TitleScreen/ButtonJoin.set_cc_button_enabled(not new_text.empty())


func _on_ButtonHost_pressed() -> void:
	var peer := NetworkedMultiplayerENet.new()
	var port := edit_host_port.get_text()
	peer.create_server(int(port) if not port.empty() else DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	init_network_manager(peer)
	$ClickBlock.show()
	transition_to_lobby = true
	$TimerTransition.start()


func _on_ButtonJoin_pressed() -> void:
	var peer := NetworkedMultiplayerENet.new()
	var ip := edit_join_ip.get_text()
	var port := edit_join_port.get_text()
	peer.create_client(ip if not ip.empty() else DEFAULT_IP, int(port) if not port.empty() else DEFAULT_PORT)
	NetworkManager.set_my_name(edit_name.get_text().strip_edges())
	peer.connect("connection_succeeded", self, "_on_join_succeeded", [peer], CONNECT_ONESHOT | CONNECT_REFERENCE_COUNTED)
	$TitleScreen/TimerTimeout.start()
	get_tree().set_network_peer(peer)
	
#	init_network_manager(peer)
#	$ClickBlock.show()
#	transition_to_lobby = true
#	$TimerTransition.start()
	
	
func init_network_manager(peer: NetworkedMultiplayerENet) -> void:
	NetworkManager.set_my_name(edit_name.get_text().strip_edges())
	NetworkManager.my_connection = peer
	NetworkManager.add_player(get_tree().get_network_unique_id())
	
	lobby_init()

func _on_ButtonExit_button_down() -> void:
	get_tree().quit()


func _on_TimerTransition_timeout() -> void:
	#$SoundTransition.play(0.25)
	$AnimationPlayer.play("to_lobby" if transition_to_lobby else "to_title")
	if transition_to_lobby:
		$Lobby/TimerAddMe.start()
	else:
		#$Lobby/TimerRemoveMe.start()
		_on_TimerRemoveMe_timeout()
	#$TimerLobby.start()
	
	
func _on_join_succeeded(peer: NetworkedMultiplayerENet) -> void:
	init_network_manager(peer)
	$ClickBlock.show()
	transition_to_lobby = true
	$TimerTransition.start()
	$TitleScreen/TimerTimeout.stop()
	
	
func _on_TimerTimeout_timeout() -> void:
	NetworkManager.show_notification("Failed to connect to the indicated server.")

# LOBBY ===========================================================================================

func lobby_init() -> void:
	NetworkManager.connect("player_connected", self, "_on_player_connected")
	NetworkManager.connect("player_disconnected", self, "_on_player_disconnected")
	if not get_tree().is_network_server():
		get_tree().connect("server_disconnected", self, "_on_server_disconnect", [], CONNECT_REFERENCE_COUNTED)
		$Lobby/ButtonStart.hide()
	else:
		$Lobby/SettingsBlocker.hide()
		$Lobby/LabelWaiting.hide()
	
	
func lobby_deinit() -> void:
	NetworkManager.disconnect("player_connected", self, "_on_player_connected")
	NetworkManager.disconnect("player_disconnected", self, "_on_player_disconnected")
	if not get_tree().is_network_server():
		get_tree().disconnect("server_disconnected", self, "_on_server_disconnect")
	

func add_player(player_name: String, is_me: bool, is_host: bool) -> void:
	var this_player := LobbyPlayer.instance() as VBoxContainer
	this_player.get_node("Name").set_text(player_name)
	if is_me:
		this_player.get_node("You").show()
	if is_host:
		this_player.get_node("Host").show()
	
	players_grid.add_child(this_player)
	
	if NetworkManager.get_player_count() >= 3:
		$Lobby/ButtonStart.set_cc_button_enabled(true)


func remove_player(player_name: String) -> void:
	for player in players_grid.get_children():
		if player.get_node("Name").get_text() == player_name:
			player.queue_free()
			break
			
	if NetworkManager.get_player_count() < 3:
		$Lobby/ButtonStart.set_cc_button_enabled(false)
		
		
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
	add_player(NetworkManager.players[id]["name"], false, id == 1)
	
	
func _on_player_disconnected(_id: int, player_name: String) -> void:
	remove_player(player_name)
	
	
func _on_server_disconnect() -> void:
	transition_to_lobby = false
	_on_TimerTransition_timeout()
	NetworkManager.show_notification("Disconnected from host server.")
	

func _on_TimerAddMe_timeout() -> void:
	add_player(NetworkManager.players[get_tree().get_network_unique_id()]["name"], true, get_tree().is_network_server())
	
	
func _on_TimerRemoveMe_timeout() -> void:
	lobby_deinit()
	NetworkManager.my_connection.close_connection()
	NetworkManager.my_connection = null
	NetworkManager.clear_players()
	#get_tree().set_network_peer(null)


func _on_ButtonExitLobby_pressed() -> void:
	$ClickBlock.show()
	transition_to_lobby = false
	$TimerTransition.start()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	$ClickBlock.hide()
	if anim_name == "to_title":
		for child in $Lobby/Players.get_children():
			child.queue_free()
	elif anim_name == "to_game":
		get_tree().change_scene(game_scene)
			
			
func _on_TimerStart_timeout() -> void:
	if get_tree().is_network_server():
		rpc("start_game")
		

func _on_ButtonStart_pressed() -> void:
	rpc("start_game_effects")
	
	
remotesync func start_game_effects() -> void:
	$Lobby/SoundStart.play()
	$ClickBlock.show()
	$Lobby/TimerStart.start()
	
	
remotesync func start_game() -> void:
	if get_tree().is_network_server():
		NetworkManager.randomize_player_order()
		NetworkManager.rpc("set_player_order", NetworkManager.player_order)
		
		var shuffled := Themes.duplicate()
		shuffled.shuffle()
		NetworkManager.rpc("set_random_theme", shuffled[0])
	
	$AnimationPlayer.play("to_game")
