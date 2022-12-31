extends Node

signal player_connected(id)
signal player_disconnected(id, player_name)

const NotificationPrefab := preload("res://prefabs/notification.tscn")

var my_connection: NetworkedMultiplayerENet = null

var player_order_initial := []
var player_order := []
var players := {}
var self_data := { "name": "" }

var players_ready := {}

var player_stories := []

var timer_max := 60
var peek_words := 10
var random_theme := String()
var show_theme := false
var timer := -1

var client_ip := String()
var client_port := String()
var client_name := String()
var is_client := false

var title_transition := false
var coming_from_game := false

enum ReadyState {
	GameStart,
	RoundTimer,
	StorySync,
	RoundEndHalfFlip,
	RoundEndFullFlip,
	
	ResultsStart,
}


func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_on_player_connect")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnect")
	randomize()
	

func set_my_name(player_name: String) -> void:
	self_data["name"] = player_name
	

func _on_player_connect(id: int) -> void:
	print_debug("%s connected" % id)
	add_player(id)
	rpc_id(id, "send_player_info", self_data)


func _on_player_disconnect(id: int) -> void:
	print_debug("%s disconnected" % id)
	var player_name: String = players[id]["name"]
	remove_player(id)
	emit_signal("player_disconnected", id, player_name)
	
	
func show_notification(what: String) -> void:
	var notif := NotificationPrefab.instance()
	notif.get_node("Notification/Text").set_text(what)
	get_tree().get_root().call_deferred("add_child", notif)
	

func add_player(id: int) -> void:
	player_order_initial.push_back(id)
	player_order.push_back(id)
	players[id] = self_data
	
	
func remove_player(id: int) -> void:
	player_order_initial.erase(id)
	player_order.erase(id)
	players.erase(id)
	
	
func clear_players() -> void:
	players.clear()
	player_order.clear()
	
	
func get_player_count() -> int:
	return players.size()
	
	
func randomize_player_order() -> void:
	player_order.shuffle()
	
	
func set_player_ready(ready_stage: int, player: int) -> void:
	if not players_ready.has(ready_stage):
		players_ready[ready_stage] = {}
		
	players_ready[ready_stage][player] = true
	
	
func are_all_players_ready(ready_stage: int) -> bool:
	return players_ready.has(ready_stage) and players_ready[ready_stage].size() == NetworkManager.player_order.size()
	
	
func clear_players_ready(ready_stage: int) -> void:
	if players_ready.has(ready_stage):
		players_ready[ready_stage].clear()
		
		
puppetsync func set_player_order_initial(order: Array) -> void:
	player_order_initial = order
	
	
puppetsync func set_timer_max(value: int) -> void:
	timer_max = value
	
	
puppetsync func set_peek_words(value: int) -> void:
	peek_words = value
	
	
puppetsync func set_show_theme(value: bool) -> void:
	show_theme = value
	
	
puppetsync func set_random_theme(value: String) -> void:
	random_theme = value
	
	
puppet func set_player_order(order: Array) -> void:
	player_order = order
	
	
remote func send_player_info(info: Dictionary) -> void:
	var id := get_tree().get_rpc_sender_id()
	players[id] = info
	emit_signal("player_connected", id)
