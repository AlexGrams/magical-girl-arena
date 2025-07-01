class_name DialogueBox
extends Control
## Displays lines of dialogue. Determines when dialogue is played and randomly decides which 
## dialogue to run.


## Parent folder for dialogue resources.
const DIALOGUE_DATA_FOLDER_PATH: String = "res://Dialogue/DialogueData/"

## Map containing DialogueData for all dialogue sequences in the game.
## Key: Constants.DialoguePlayTrigger - When the dialogue can be played.
## Value: Array[DialogueData] - List of dialogues that can be played at that trigger.
var _dialogue: Dictionary = {}
## Maps instantiated DialogueData to String path to the DialogueData's .tres file.
var _dialogue_paths: Dictionary = {}
var _dialogue_line_container: PackedScene = preload("res://UI/dialogue_line_container.tscn")
## Dictionary used as set where keys are player characters that are in the game.
var _player_character_set: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for dialogue_data_file_name: String in DirAccess.open(DIALOGUE_DATA_FOLDER_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in dialogue_data_file_name:
			dialogue_data_file_name = dialogue_data_file_name.trim_suffix('.remap')
		
		var full_path: String = DIALOGUE_DATA_FOLDER_PATH + dialogue_data_file_name
		var dialogue_data: DialogueData = ResourceLoader.load(full_path)
		if not _dialogue.has(dialogue_data.play_trigger):
			_dialogue[dialogue_data.play_trigger] = []
		_dialogue[dialogue_data.play_trigger].append(dialogue_data)
		_dialogue_paths[dialogue_data] = full_path
	
	# TODO: For testing, wait some time before trying to start the dialogue.
	if multiplayer.is_server():
		await get_tree().create_timer(2.0).timeout
		start_dialogue(Constants.DialoguePlayTrigger.START)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Randomly selects a dialogue to run. Only call on server.
func start_dialogue(trigger: Constants.DialoguePlayTrigger) -> void:
	var dialogue_choices: Array[DialogueData] = []
	
	# Get all the characters that are in the game if we don't have it already.
	if _player_character_set.is_empty():
		for data: Dictionary in GameState.players.values():
			_player_character_set[data["character"]] = true
	
	print(_player_character_set)
	
	for dialogue: DialogueData in _dialogue[trigger]:
		var can_add: bool = true
		for character: Constants.Character in dialogue.get_characters():
			if not _player_character_set.has(character):
				can_add = false
				break
		if can_add:
			dialogue_choices.append(dialogue)
	
	if len(dialogue_choices) <= 0:
		return
	
	_run_dialogue.rpc(_dialogue_paths[dialogue_choices.pick_random()])


## Play a full dialogue sequence. Should only be called by the server.
@rpc("any_peer", "call_local", "reliable")
func _run_dialogue(dialogue_data_path: String) -> void:
	var dialogue_data: DialogueData = load(dialogue_data_path)
	_show_line(dialogue_data.lines[0])


## Display a new line of dialogue.
func _show_line(line: DialogueLine) -> void:
	var dialogue_line_container: DialogueLineContainer = _dialogue_line_container.instantiate()
	dialogue_line_container.set_up(line)
	add_child(dialogue_line_container, true)
