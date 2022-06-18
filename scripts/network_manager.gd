extends Node

signal player_connected(id)
signal player_disconnected(id, player_name)

var my_connection: NetworkedMultiplayerENet = null

var player_order := []
var players := {}
var self_data := { "name": "" }

var players_ready := {}

var player_stories := {}

var timer_max := 60
var peek_words := 10
var show_theme := false
var timer := -1


func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_on_player_connect")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnect")
	

func set_my_name(player_name: String) -> void:
	self_data["name"] = player_name
	

func _on_player_connect(id: int) -> void:
	print("%s connected" % id)
	add_player(id)
	rpc_id(id, "send_player_info", self_data)


func _on_player_disconnect(id: int) -> void:
	print("%s disconnected" % id)
	var player_name: String = players[id]["name"]
	remove_player(id)
	emit_signal("player_disconnected", id, player_name)
	

func add_player(id: int) -> void:
	player_order.push_back(id)
	players[id] = self_data
	
	
func remove_player(id: int) -> void:
	player_order.erase(id)
	players.erase(id)
	
	
func clear_players() -> void:
	players.clear()
	player_order.clear()
	
	
func get_player_count() -> int:
	return players.size()
	
	
func randomize_player_order() -> void:
	player_order.shuffle()
	
	
remotesync func set_timer(value: int) -> void:
	timer = value
	
	
remotesync func set_timer_max(value: int) -> void:
	timer_max = value
	
	
remotesync func set_peek_words(value: int) -> void:
	peek_words = value
	
	
remotesync func set_show_theme(value: bool) -> void:
	show_theme = value
	
	
remotesync func set_player_story(player_id: int, story: String) -> void:
	players[player_id]["story"] = story
	
	
remote func set_player_order(order: Array) -> void:
	player_order = order
	
	
remote func send_player_info(info: Dictionary) -> void:
	var id := get_tree().get_rpc_sender_id()
	players[id] = info
	emit_signal("player_connected", id)
