extends Control

export(String, FILE, "*.tscn") var lobby_scene := String()

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 31400
const MAX_PLAYERS := 12

onready var edit_name := $EditName as LineEdit
onready var edit_join_ip := $EditJoinIp as LineEdit
onready var edit_join_port := $EditJoinPort as LineEdit
onready var edit_host_port := $EditHostPort as LineEdit


func _on_ButtonHost_button_down() -> void:
	var peer := NetworkedMultiplayerENet.new()
	var port := edit_host_port.get_text()
	peer.create_server(int(port) if not port.empty() else DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	init_network_manager(peer)
	get_tree().change_scene(lobby_scene)


func _on_ButtonJoin_button_down() -> void:
	var peer := NetworkedMultiplayerENet.new()
	var ip := edit_join_ip.get_text()
	var port := edit_join_port.get_text()
	peer.create_client(ip if not ip.empty() else DEFAULT_IP, int(port) if not port.empty() else DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	
	init_network_manager(peer)
	get_tree().change_scene(lobby_scene)
	
	
func init_network_manager(peer: NetworkedMultiplayerENet) -> void:
	NetworkManager.set_my_name(edit_name.get_text())
	NetworkManager.my_connection = peer
	NetworkManager.add_player(get_tree().get_network_unique_id())


func _on_ButtonExit_button_down() -> void:
	get_tree().quit()
