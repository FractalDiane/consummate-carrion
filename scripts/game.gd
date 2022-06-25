extends Control

var stories := []
var player_order := []

var my_current_prefix := String()

var current_round := 0
var timer_count := 0.0
var my_timer_up := false
var game_started := false

var current_story_text := String()

onready var story_text := $StoryBase/Story as TextEdit
onready var label_timer := $LabelTimer as Label


func _ready() -> void:
	if get_tree().is_network_server():
		for player in NetworkManager.player_order:
			var new_story := {}
			new_story["text"] = [String()]
			new_story["owner"] = player
			stories.push_back(new_story)
	
	rpc_id(1, "set_player_ready")
		
		
func _process(delta: float) -> void:
	if game_started:
		timer_count -= delta
		label_timer.set_text(get_time_string())
		
		if not my_timer_up and timer_count <= 0.0:
			rpc_id(1, "send_story_info", current_story_text.replace(my_current_prefix, "").strip_edges())
			my_timer_up = true
			rpc_id(1, "set_player_ready")
		
		
remotesync func set_player_ready() -> void:
	NetworkManager.players_ready[get_tree().get_rpc_sender_id()] = true
	if get_tree().is_network_server() and NetworkManager.players_ready.size() == NetworkManager.player_order.size():
		rotate_players(not game_started)
		rpc("sync_story_info", stories, player_order)
		if not game_started:
			rpc("begin_game")
		else:
			rpc("start_new_round", true)
			
			
remote func sync_story_info(total_stories: Array, rotated_players: Array) -> void:
	stories = total_stories
	player_order = rotated_players
	
	
remotesync func send_story_info(text: String) -> void:
	var sender := get_tree().get_rpc_sender_id()
	var index := player_order.find(sender)
	stories[index]["text"].push_back(text)

		
remotesync func begin_game() -> void:
	NetworkManager.players_ready.clear()
	start_new_round(false)


remotesync func start_new_round(after_first: bool) -> void:
	if after_first:
		current_round += 1
		
	if current_round < NetworkManager.get_player_count():
		timer_count = NetworkManager.timer_max
		var current_story: Dictionary = stories[player_order.find(get_tree().get_network_unique_id())]
		
		var split_total := PoolStringArray(current_story["text"]).join(" ").split(" ")
		split_total.invert()
		var result := PoolStringArray()
		for i in range(NetworkManager.peek_words):
			if i >= split_total.size():
				break
				
			result.push_back(split_total[-(i + 1)])
			
		#result.invert()
		my_current_prefix = result.join(" ")
		current_story_text = my_current_prefix
		story_text.set_text(my_current_prefix)
		
		NetworkManager.players_ready.clear()
		my_timer_up = false
		game_started = true
	else:
		print("FINISHED")


func _on_Story_text_changed() -> void:
	if not story_text.get_text().begins_with(my_current_prefix):
		story_text.set_text(current_story_text)
	else:
		current_story_text = story_text.get_text()


func get_time_string() -> String:
	var time := timer_count + 1
	return str(int(floor(time / 60))) + ":" + ("%.f" % floor(fmod(time, 60.0))).pad_zeros(2)


func rotate_players(init: bool) -> void:
	player_order = rotate_array(player_order, 1) if not init else NetworkManager.player_order
		
	
func rotate_array(array: Array, amount: int) -> Array:
	var ret := Array()
	for i in range(len(array)):
		ret.push_back(array[wrapi(i + amount, 0, len(array))])
		
	return ret
