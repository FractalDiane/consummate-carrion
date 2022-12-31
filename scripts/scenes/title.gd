extends Control

export(String, FILE, "*.tscn") var game_scene := String()

const LobbyPlayer := preload("res://prefabs/lobby_player.tscn")

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 12

var transition_to_lobby := false
var in_lobby := false

onready var edit_name := $TitleScreen/EditName as LineEdit
onready var edit_join_ip := $TitleScreen/EditJoinIp as LineEdit
onready var edit_join_port := $TitleScreen/EditJoinPort as LineEdit
onready var edit_host_port := $TitleScreen/EditHostPort as LineEdit
onready var button_options := $TitleScreen/ButtonOptions as Control

onready var players_grid := $Lobby/Players as GridContainer
onready var button_start := $Lobby/ButtonStart as Control
onready var button_exit_lobby := $Lobby/ButtonExitLobby as Control
onready var spinbox_timer := $Lobby/Settings/HBoxContainer/SpinBoxTime as SpinBox
onready var spinbox_words := $Lobby/Settings/HBoxContainer2/SpinBoxWords as SpinBox
onready var button_theme := $Lobby/Settings/HBoxContainer3/CheckButtonTheme as Control

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
	"Talent Show",
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
	"Circus",
	"Magic Show",
	"Medieval",
	"Ghosts",
	"Holidays",
	"Celebrities",
	"Stormy Night",
	"Pirates",
	"Spring Cleaning",
	"Outer Space",
	"Royal Ball",
	"Haunted House",
]

func _ready() -> void:
	$TitleScreen/ButtonHost.set_cc_button_enabled(false)
	$TitleScreen/ButtonJoin.set_cc_button_enabled(false)
	$Lobby/ButtonStart.set_cc_button_enabled(false)
	
	if get_tree().get_current_scene() == self:
		$Music.play()
		$TitleScreen/Title.set_bbcode("[tornado radius=5]Consummate Carrion[/tornado]")
		$CanvasLayer/ClickBlock.hide()
		
	if OptionsManager.reduce_motion_enabled():
		$TitleScreen/Title.set_bbcode("Consummate Carrion")
		$Lobby/LabelLobby.set_bbcode("Lobby")
		
	if NetworkManager.coming_from_game:
		jump_to_lobby()
		lobby_init(true)
		if get_tree().get_current_scene() == self:
			NetworkManager.coming_from_game = false
			
	edit_name.text = NetworkManager.cached_name
	edit_host_port.text = NetworkManager.cached_host_port
	edit_join_ip.text = NetworkManager.cached_join_ip
	edit_join_port.text = NetworkManager.cached_join_port
	
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next") or Input.is_action_just_pressed("ui_focus_prev"):
		if get_focus_owner() == null:
			if in_lobby:
				button_exit_lobby.grab_focus()
			else:
				button_options.grab_focus()

# TITLE SCREEN ====================================================================================

func _on_EditName_text_changed(new_text: String) -> void:
	$TitleScreen/ButtonHost.set_cc_button_enabled(not new_text.empty())
	$TitleScreen/ButtonJoin.set_cc_button_enabled(not new_text.empty())


func _on_ButtonHost_pressed() -> void:
	var peer := NetworkedMultiplayerENet.new()
	var port := edit_host_port.get_text()
	peer.create_server(int(port) if not port.empty() else DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	NetworkManager.cached_name = edit_name.get_text()
	NetworkManager.cached_host_port = edit_host_port.get_text()
	
	init_network_manager(peer)
	$CanvasLayer/ClickBlock.show()
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
	
	NetworkManager.cached_name = edit_name.get_text()
	NetworkManager.cached_join_ip = edit_join_ip.get_text()
	NetworkManager.cached_join_port = edit_join_port.get_text()
	
#	init_network_manager(peer)
#	$CanvasLayer/ClickBlock.show()
#	transition_to_lobby = true
#	$TimerTransition.start()


func _on_ButtonOptions_pressed() -> void:
	$CanvasLayer/ClickBlock.show()
	_on_TimerOptions_timeout()
	#$TitleScreen/TimerOptions.start()


func _on_ButtonExit_pressed() -> void:
	$CanvasLayer/ClickBlock.show()
	$TitleScreen/TimerExit.start()
	
	
func init_network_manager(peer: NetworkedMultiplayerENet) -> void:
	NetworkManager.set_my_name(edit_name.get_text().strip_edges())
	NetworkManager.my_connection = peer
	NetworkManager.add_player(get_tree().get_network_unique_id())
	
	lobby_init(true)
	
	
func jump_to_lobby() -> void:
	$AnimationPlayer.play("to_lobby")
	$AnimationPlayer.seek(1)
	_on_AnimationPlayer_animation_finished("to_lobby")
	for player in NetworkManager.player_order_initial:
		add_player(NetworkManager.players[player]["name"], player == get_tree().get_network_unique_id(), player == 1)
	if get_tree().is_network_server():
		spinbox_timer.disconnect("value_changed", self, "_on_SpinBoxTime_value_changed")
		spinbox_words.disconnect("value_changed", self, "_on_SpinBoxWords_value_changed")
		button_theme.disconnect("toggled", self, "_on_CheckButtonTheme_toggled")
		
		spinbox_timer.set_value(NetworkManager.timer_max)
		spinbox_words.set_value(NetworkManager.peek_words)
		button_theme.set_cc_button_checked(NetworkManager.show_theme)
		
		spinbox_timer.connect("value_changed", self, "_on_SpinBoxTime_value_changed")
		spinbox_words.connect("value_changed", self, "_on_SpinBoxWords_value_changed")
		button_theme.connect("toggled", self, "_on_CheckButtonTheme_toggled")
	
		rpc("sync_setting_displays", NetworkManager.timer_max, NetworkManager.peek_words, NetworkManager.show_theme)


func _on_TimerTransition_timeout() -> void:
	#$SoundTransition.play(0.25)
	var anim := "to_lobby" if transition_to_lobby else "to_title"
	$AnimationPlayer.play(anim)
	if OptionsManager.reduce_motion_enabled():
		$AnimationPlayer.seek(1, true)
		_on_AnimationPlayer_animation_finished(anim)
		
	if transition_to_lobby:
		$Lobby/TimerAddMe.start()
	else:
		#$Lobby/TimerRemoveMe.start()
		_on_TimerRemoveMe_timeout()
	#$TimerLobby.start()
	
	
func _on_join_succeeded(peer: NetworkedMultiplayerENet) -> void:
	init_network_manager(peer)
	$CanvasLayer/ClickBlock.show()
	transition_to_lobby = true
	$TimerTransition.start()
	$TitleScreen/TimerTimeout.stop()
	
	
func _on_TimerOptions_timeout() -> void:
	if OptionsManager.reduce_motion_enabled():
		get_tree().change_scene("res://scenes/options.tscn")
		OptionsManager.play_sound_click()
	else:
		var options := preload("res://scenes/options.tscn").instance() as Control
		options.rect_position.y = -720
		get_tree().get_current_scene().add_child(options)
		$AnimationPlayer.play("to_options")
	
	
func _on_TimerTimeout_timeout() -> void:
	NetworkManager.show_notification("Failed to connect to the indicated server.")
	
	
func _on_TimerExit_timeout() -> void:
	get_tree().quit()

# LOBBY ===========================================================================================

func lobby_init(signals: bool) -> void:
	if signals:
		NetworkManager.connect("player_connected", self, "_on_player_connected")
		NetworkManager.connect("player_disconnected", self, "_on_player_disconnected")
		
	if not get_tree().is_network_server():
		if signals:
			get_tree().connect("server_disconnected", self, "_on_server_disconnect", [], CONNECT_REFERENCE_COUNTED)
		$Lobby/ButtonStart.hide()
	else:
		$Lobby/SettingsBlocker.hide()
		$Lobby/LabelWaiting.hide()
		button_exit_lobby.focus_next = button_start.get_path()
		button_exit_lobby.focus_previous = button_theme.get_path()
		
	in_lobby = true
	
	if get_focus_owner() != null:
		get_focus_owner().release_focus()
		
		#_on_SpinBoxTime_value_changed(spinbox_timer.value)
		#_on_SpinBoxWords_value_changed(spinbox_words.value)
		#_on_CheckButtonTheme_toggled(button_theme.pressed)
	
	
func lobby_deinit() -> void:
	NetworkManager.disconnect("player_connected", self, "_on_player_connected")
	NetworkManager.disconnect("player_disconnected", self, "_on_player_disconnected")
	if not get_tree().is_network_server():
		get_tree().disconnect("server_disconnected", self, "_on_server_disconnect")
		
	button_exit_lobby.focus_next = button_exit_lobby.get_path()
	button_exit_lobby.focus_previous = button_exit_lobby.get_path()
	in_lobby = false
	
	if get_focus_owner() != null:
		get_focus_owner().release_focus()
	

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
		
		
puppet func sync_setting_displays(time: float, words: float, show_theme: bool) -> void:
	spinbox_timer.disconnect("value_changed", self, "_on_SpinBoxTime_value_changed")
	spinbox_words.disconnect("value_changed", self, "_on_SpinBoxWords_value_changed")
	button_theme.disconnect("toggled", self, "_on_CheckButtonTheme_toggled")
	
	spinbox_timer.set_value(time)
	spinbox_words.set_value(words)
	button_theme.set_cc_button_checked(show_theme)
	
	spinbox_timer.connect("value_changed", self, "_on_SpinBoxTime_value_changed")
	spinbox_words.connect("value_changed", self, "_on_SpinBoxWords_value_changed")
	button_theme.connect("toggled", self, "_on_CheckButtonTheme_toggled")


func _on_SpinBoxTime_value_changed(value: float) -> void:
	if get_tree().is_network_server():
		NetworkManager.rpc("set_timer_max", int(value))
		rpc("sync_setting_displays", spinbox_timer.get_value(), spinbox_words.get_value(), button_theme.is_cc_button_pressed())
	
	
func _on_SpinBoxWords_value_changed(value: float) -> void:
	if get_tree().is_network_server():
		NetworkManager.rpc("set_peek_words", int(value))
		rpc("sync_setting_displays", spinbox_timer.get_value(), spinbox_words.get_value(), button_theme.is_cc_button_pressed())
	
	
func _on_CheckButtonTheme_toggled(button_pressed: bool) -> void:
	if get_tree().is_network_server():
		NetworkManager.rpc("set_show_theme", button_pressed)
		rpc("sync_setting_displays", spinbox_timer.get_value(), spinbox_words.get_value(), button_theme.is_cc_button_pressed())
	
	
func _on_player_connected(id: int) -> void:
	add_player(NetworkManager.players[id]["name"], false, id == 1)
	_on_SpinBoxTime_value_changed(spinbox_timer.value)
	_on_SpinBoxWords_value_changed(spinbox_words.value)
	_on_CheckButtonTheme_toggled(button_theme.is_cc_button_pressed())
	
	
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
	$CanvasLayer/ClickBlock.show()
	transition_to_lobby = false
	$TimerTransition.start()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	$CanvasLayer/ClickBlock.hide()
	if anim_name == "to_title":
		for child in $Lobby/Players.get_children():
			child.queue_free()
	elif anim_name == "to_game" or anim_name == "to_game_reducedmotion":
		get_tree().change_scene(game_scene)
	elif anim_name == "to_options":
		get_tree().change_scene("res://scenes/options.tscn")
			
			
func _on_TimerStart_timeout() -> void:
	if get_tree().is_network_server():
		rpc("start_game")
		

func _on_ButtonStart_pressed() -> void:
	rpc("start_game_effects")
	
	
remotesync func start_game_effects() -> void:
	$Music.stop()
	$Lobby/SoundStart.play()
	$CanvasLayer/ClickBlock.show()
	$Lobby/TimerStart.start()
	
	
remotesync func start_game() -> void:
	if get_tree().is_network_server():
		NetworkManager.randomize_player_order()
		NetworkManager.rpc("set_player_order", NetworkManager.player_order)
		NetworkManager.rpc("set_player_order_initial", NetworkManager.player_order_initial)
		
		var shuffled := Themes.duplicate()
		shuffled.shuffle()
		NetworkManager.rpc("set_random_theme", shuffled[0])
	
	$AnimationPlayer.play("to_game_reducedmotion" if OptionsManager.reduce_motion_enabled() else "to_game")
