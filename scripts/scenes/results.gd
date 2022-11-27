extends Control

var page_index := 0

onready var prompt := $Prompt as Label
onready var story := $StoryBase/Story as TextEdit

func _ready() -> void:
	if not get_tree().is_network_server():
		$ButtonLeft.hide()
		$ButtonRight.hide()
	else:
		$ButtonLeft.set_cc_button_enabled(false)


remotesync func set_player_ready(ready_state: int) -> void:
	NetworkManager.set_player_ready(ready_state, get_tree().get_rpc_sender_id())
	if get_tree().is_network_server() and NetworkManager.are_all_players_ready(ready_state):
		match ready_state:
			NetworkManager.ReadyState.ResultsStart:
				rpc("show_current_story")
#				rotate_players(true)
#				rpc("sync_story_info", stories, player_order, false)
#				rpc("begin_game")
#			ReadyState.RoundTimer:
#				rpc("end_round")
#			ReadyState.StorySync:
#				rpc("setup_story", true)
#			ReadyState.RoundEndHalfFlip:
#				if game_completed:
#					rpc("show_game_finished")
#
#				rpc("end_round_2")
#			ReadyState.RoundEndFullFlip:
#				if not game_completed:
#					rpc("start_new_round", false)
#				else:
#					rpc("goto_results")
				
		NetworkManager.clear_players_ready(ready_state)
	
	
puppetsync func show_current_story() -> void:
	var story_array  := PoolStringArray(NetworkManager.player_stories[page_index]["text"])
	var story_text := story_array.join(" ")
	story.set_text(story_text)
	
	prompt.set_text("Story started by " + NetworkManager.players[NetworkManager.player_stories[page_index]["owner"]]["name"])
	$AnimationPlayerPrompt.play("type_prompt")
	
		
puppetsync func move_page(right: bool) -> void:
	page_index += 1 - 2 * int(not right)
	if get_tree().is_network_server():
		$ButtonLeft.set_cc_button_enabled(page_index > 0)
		$ButtonRight.set_cc_button_enabled(page_index < NetworkManager.get_player_count() - 1)


func _on_TimerStart_timeout() -> void:
	rpc_id(1, "set_player_ready", NetworkManager.ReadyState.ResultsStart)


func _on_ButtonLeft_pressed() -> void:
	rpc("move_page", false)
	rpc("show_current_story")


func _on_ButtonRight_pressed() -> void:
	rpc("move_page", true)
	rpc("show_current_story")
