extends Control

var stories := []
var player_order := []

var my_current_prefix := String()

var current_round := 0
var timer_count := 0.0
var my_timer_up := false
var game_started := false
var prompt_retyped := false
var game_completed := false

var current_story_text := String()

var music_choices := [
	preload("res://audio/music/game1.ogg"),
	preload("res://audio/music/game2.ogg"),
	preload("res://audio/music/game3.ogg"),
]

onready var prompt := $Prompt as Label
onready var story_text := $StoryBase/Story as TextEdit
onready var timer_node := $Timer as Control
onready var anim_player := $AnimationPlayer as AnimationPlayer
onready var sound_tick := $SoundTick as AudioStreamPlayer

func _ready() -> void:
	music_choices.shuffle()
	$Music.stream = music_choices[0]
	
	if get_tree().is_network_server():
		for player in NetworkManager.player_order:
			var new_story := {}
			new_story["text"] = []
			new_story["owner"] = player
			stories.push_back(new_story)
	else:
		get_tree().connect("server_disconnected", self, "_on_server_disconnect", [], CONNECT_REFERENCE_COUNTED)
		
	if NetworkManager.show_theme:
		prompt.text = "Start writing a story with the theme: " + NetworkManager.random_theme
		$AnimationPlayerPrompt.play("type_prompt_theme")
	else:
		prompt.text = "Start writing a story."
		$AnimationPlayerPrompt.play("type_prompt")
		
		
func _process(delta: float) -> void:
	if game_started:
		timer_count = max(timer_count - delta, 0.0)
		timer_node.time_value = timer_count
		
		if timer_count < 5.0 and not my_timer_up and not sound_tick.is_playing():
			sound_tick.play()
		
		if not my_timer_up and timer_count <= 0.0:
			sound_tick.stop()
			$SoundRoundEnd.play()
			if current_round == NetworkManager.get_cached_player_count():
				$AnimationPlayerFadeMusic.play("fade_music")
			else:
				$Music.set_stream_paused(true)
			
			rpc_id(1, "send_story_info", current_story_text.replace(my_current_prefix, "").strip_edges())
			rpc_id(1, "set_player_ready", NetworkManager.ReadyState.RoundTimer)
			story_text.set_readonly(true)
			my_timer_up = true
		
		
remotesync func set_player_ready(ready_state: int) -> void:
	NetworkManager.set_player_ready(ready_state, get_tree().get_rpc_sender_id())
	if get_tree().is_network_server() and NetworkManager.are_all_players_ready(ready_state):
		match ready_state:
			NetworkManager.ReadyState.GameStart:
				rotate_players(true)
				rpc("sync_story_info", stories, player_order, false)
				rpc("begin_game")
			NetworkManager.ReadyState.RoundTimer:
				rpc("end_round")
			NetworkManager.ReadyState.StorySync:
				rpc("setup_story", true)
			NetworkManager.ReadyState.RoundEndHalfFlip:
				if game_completed:
					rpc("show_game_finished")
					
				rpc("end_round_2")
			NetworkManager.ReadyState.RoundEndFullFlip:
				if not game_completed:
					rpc("start_new_round", false)
				else:
					rpc("goto_results")
				
		NetworkManager.clear_players_ready(ready_state)
			
			
puppet func sync_story_info(total_stories: Array, rotated_players: Array, set_ready: bool) -> void:
	stories = total_stories
	player_order = rotated_players
	if set_ready:
		rpc_id(1, "set_player_ready", NetworkManager.ReadyState.StorySync)
	
	
remotesync func send_story_info(text: String) -> void:
	var index := player_order.find(get_tree().get_rpc_sender_id())
	print_debug(get_tree().get_rpc_sender_id(), " -> ", text, "(index ", index, ")")
	stories[index]["text"].push_back(text)

		
puppetsync func begin_game() -> void:
	NetworkManager.players_ready.clear()
	start_new_round(true)
	
	
puppetsync func end_round() -> void:
	$TimerRoundEnd.start()
	
	
puppetsync func end_round_2() -> void:
	$AnimationPlayerRound.play("unflip_story_reducedmotion" if OptionsManager.reduce_motion_enabled() else "unflip_story")
	
	
puppetsync func show_game_finished() -> void:
	$StoryBase/GameComplete.show()
	story_text.hide()
	
	
puppetsync func goto_results() -> void:
	NetworkManager.player_stories = stories.duplicate()
	
	var results := preload("res://scenes/results.tscn").instance() as Control
	$InstancedScene.add_child(results)
	if OptionsManager.reduce_motion_enabled():
		anim_player.play("to_results_reducedmotion")
	else:
		results.rect_position.x = 1280
		anim_player.play("to_results")
	
	
puppetsync func setup_story(after_first_round: bool) -> void:
	if after_first_round:
		current_round += 1
		
	if current_round < NetworkManager.get_cached_player_count():
		var current_story: Dictionary = stories[player_order.find(get_tree().get_network_unique_id())]
		
		var split_total := PoolStringArray(current_story["text"]).join(" ").split(" ")
		split_total.invert()
		var result := PoolStringArray()
		for i in range(NetworkManager.peek_words):
			if i >= split_total.size():
				break
				
			result.push_back(split_total[(i)])
			
		result.invert()
		my_current_prefix = result.join(" ")
		current_story_text = my_current_prefix
		story_text.set_text(my_current_prefix)
	else:
		game_completed = true
		
	rpc_id(1, "set_player_ready", NetworkManager.ReadyState.RoundEndHalfFlip)
	

puppetsync func start_new_round(first_round: bool) -> void:
	$Music.set_stream_paused(false)
	if not first_round and not prompt_retyped:
		if NetworkManager.show_theme:
			prompt.text = "Continue the story. Theme: " + NetworkManager.random_theme
		else:
			prompt.text = "Continue the story."
			
		$AnimationPlayerPrompt.play("type_prompt")
		prompt_retyped = true
	
	NetworkManager.players_ready.clear()
	timer_count = NetworkManager.timer_max
	$Timer.show()
	if first_round:
		$Music.play()
		
	story_text.set_readonly(false)
	my_timer_up = false
	game_started = true


func _on_Story_text_changed() -> void:
	#var cursor_col := story_text.cursor_get_column()
	#var cursor_line := story_text.cursor_get_line()
	if not story_text.get_text().begins_with(my_current_prefix) or story_text.get_text().count("\n") > 0 or story_text.get_text().count("\t") > 0:
		story_text.set_text(current_story_text)
		#story_text.cursor_set_column(cursor_col)
		#story_text.cursor_set_line(cursor_line)
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


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "transition" or anim_name == "transition_reducedmotion":
		story_text.set_readonly(false)
		rpc_id(1, "set_player_ready", NetworkManager.ReadyState.GameStart)
	elif anim_name == "to_title":
		get_tree().change_scene("res://scenes/title.tscn")
	elif anim_name == "to_results":
		get_tree().change_scene("res://scenes/results.tscn")
		
		
func _on_server_disconnect() -> void:
	return_to_title()
	NetworkManager.show_notification("Disconnected from host server.")
	
	
func return_to_title() -> void:
	$AnimationPlayerFadeMusic.play("fade_music")
	var title := preload("res://scenes/title.tscn").instance() as Control
	$InstancedScene.add_child(title)
	if OptionsManager.reduce_motion_enabled():
		anim_player.play("to_title_reducedmotion")
	else:
		title.rect_position.x = -2560
		anim_player.play("to_title")
	

func _on_TimerRoundEnd_timeout() -> void:
	$AnimationPlayerRound.play("flip_story_reducedmotion" if OptionsManager.reduce_motion_enabled() else "flip_story")
	if current_round + 1 == NetworkManager.get_cached_player_count():
		$AnimationPlayerRound2.play("flip_prompt")


func _on_AnimationPlayerRound_animation_finished(anim_name: String) -> void:
	if anim_name == "flip_story" or anim_name == "flip_story_reducedmotion":
		if get_tree().is_network_server():
			rotate_players(not game_started)
			rpc_id(1, "set_player_ready", NetworkManager.ReadyState.StorySync)
			rpc("sync_story_info", stories, player_order, true)
	elif anim_name == "unflip_story" or anim_name == "unflip_story_reducedmotion":
		rpc_id(1, "set_player_ready", NetworkManager.ReadyState.RoundEndFullFlip)
	

func _on_AnimationPlayerPrompt_animation_finished(_anim_name: String) -> void:
	if not prompt_retyped:
		anim_player.play("transition_reducedmotion" if OptionsManager.reduce_motion_enabled() else "transition")


func _on_AnimationPlayerFadeMusic_animation_finished(_anim_name: String) -> void:
	$Music.stop()
