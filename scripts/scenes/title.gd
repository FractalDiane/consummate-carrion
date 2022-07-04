extends Control

export(String, FILE, "*.tscn") var lobby_scene := String()

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 12

onready var edit_name := $TitleScreen/EditName as LineEdit
onready var edit_join_ip := $TitleScreen/EditJoinIp as LineEdit
onready var edit_join_port := $TitleScreen/EditJoinPort as LineEdit
onready var edit_host_port := $TitleScreen/EditHostPort as LineEdit


func _ready() -> void:
	pass
	#$TitleScreen/AnimationPlayer.play_backwards("transition")
#	if NetworkManager.title_transition:
#		$SoundTransition2.play()
#		NetworkManager.title_transition = false
		
	#NetworkManager.show_notification("HELLO THIS IS A NOTIFICATION YEAH")


func _on_ButtonHost_pressed() -> void:
	#var peer := NetworkedMultiplayerENet.new()
	var port := edit_host_port.get_text()
	#peer.create_server(int(port) if not port.empty() else DEFAULT_PORT, MAX_PLAYERS)
	#get_tree().set_network_peer(peer)
	#NetworkManager.client_ip = ip
	NetworkManager.client_port = port
	NetworkManager.client_name = edit_name.get_text().strip_edges()
	
	#init_network_manager(peer)
	$ClickBlock.show()
	$TimerTransition.start()
	#get_tree().change_scene(lobby_scene)


func _on_ButtonJoin_pressed() -> void:
	#var peer := NetworkedMultiplayerENet.new()
	var ip := edit_join_ip.get_text()
	var port := edit_join_port.get_text()
	#peer.create_client(ip if not ip.empty() else DEFAULT_IP, int(port) if not port.empty() else DEFAULT_PORT)
	#get_tree().set_network_peer(peer)
	NetworkManager.client_ip = ip
	NetworkManager.client_port = port
	NetworkManager.is_client = true
	NetworkManager.client_name = edit_name.get_text().strip_edges()
	
	#init_network_manager(peer)
	$ClickBlock.show()
	$TimerTransition.start()
	#get_tree().change_scene(lobby_scene)
	
	
#func init_network_manager(peer: NetworkedMultiplayerENet, my_name: String) -> void:
#	NetworkManager.set_my_name(edit_name.get_text().strip_edges())
#	NetworkManager.my_connection = peer
#	NetworkManager.add_player(get_tree().get_network_unique_id())


func _on_ButtonExit_button_down() -> void:
	get_tree().quit()


func _on_TimerTransition_timeout() -> void:
	$SoundTransition.play(0.25)
	$AnimationPlayer.play("transition")
	$TimerLobby.start()


func _on_TimerLobby_timeout() -> void:
	get_tree().change_scene(lobby_scene)

