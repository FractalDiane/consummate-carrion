extends Control

var page_index := 0

var story_to_save := String()
var prompt_to_save := String()

onready var prompt := $Prompt as Label
onready var story := $StoryBase/Story as TextEdit

func _ready() -> void:
	$CanvasLayer/SaveDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	
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


func _on_ButtonSave_pressed() -> void:
	story_to_save = story.get_text()
	prompt_to_save = prompt.get_text()
	$CanvasLayer/SaveDialog.popup()


func _on_SaveDialog_file_selected(path: String) -> void:
	if not path.empty():
		var file := File.new()
		file.open(path, File.WRITE)
		file.store_string("Consummate Carrion\n")
		file.store_string(prompt_to_save + "\n")
		file.store_string(story_to_save + "\n")
		file.close()
