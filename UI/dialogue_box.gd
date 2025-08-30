class_name DialogueBox
extends Control
## Displays lines of dialogue. Determines when dialogue is played and randomly decides which 
## dialogue to run.


## Parent folder for dialogue resources.
const DIALOGUE_DATA_FOLDER_PATH: String = "res://Dialogue/DialogueData/"
## Minimum amount of time in seconds that we wait in between displaying lines of dialogue.
const BASE_LINE_WAIT: float = 0.5
## Delay in seconds between displaying the next dialogue line per character in the current line.
const PER_CHARACTER_LINE_WAIT: float = 0.05
## Delay in seconds between removing lines from the screen after a dialogue has finished.
const DESTROY_LINE_WAIT_AFTER_DIALOGUE: float = 0.5
## Most number of dialogue lines that we show at once.
const MAX_LINES: int = 3

## Map containing DialogueData for all dialogue sequences in the game.
## Key: Constants.DialoguePlayTrigger - When the dialogue can be played.
## Value: Array[DialogueData] - List of dialogues that can be played at that trigger.
var _dialogue: Array[DialogueData] = []
## Maps instantiated DialogueData to String path to the DialogueData's .tres file.
var _dialogue_paths: Dictionary = {}
var _dialogue_line_container: PackedScene = preload("res://UI/dialogue_line_container.tscn")
## Dictionary used as set where keys are player characters that are in the game.
var _player_character_set: Dictionary = {}
## Dialogue that we're currently playing, if any.
var _running_dialogue: DialogueData = null
## Line of dialogue that we're going to display next.
var _running_dialogue_index: int = 0
## Time until the next line of dialogue is displayed.
var _dialogue_timer: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for dialogue_data_file_name: String in DirAccess.open(DIALOGUE_DATA_FOLDER_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in dialogue_data_file_name:
			dialogue_data_file_name = dialogue_data_file_name.trim_suffix('.remap')
		
		var full_path: String = DIALOGUE_DATA_FOLDER_PATH + dialogue_data_file_name
		var dialogue_data: DialogueData = ResourceLoader.load(full_path)
		_dialogue.append(dialogue_data)
		_dialogue_paths[dialogue_data] = full_path


func _process(delta: float) -> void:
	if _running_dialogue != null:
		# Play lines of dialogue in sequence, waiting some time after showing each line.
		_dialogue_timer -= delta
		if _dialogue_timer <= 0.0:
			_show_line(_running_dialogue.lines[_running_dialogue_index])
			
			_running_dialogue_index += 1
			# End dialogue if we run out of lines.
			if _running_dialogue_index >= len(_running_dialogue.lines):
				_running_dialogue = null
	elif get_child_count() > 0:
		# Delete lines of dialogue after we've finished playing a dialogue.
		_dialogue_timer -= delta
		if _dialogue_timer <= 0.0:
			_delete_oldest_child()
			_dialogue_timer = DESTROY_LINE_WAIT_AFTER_DIALOGUE


## Randomly selects a dialogue to run. Only call on server.
func start_dialogue(conditions: Array[Constants.DialoguePlayCondition]) -> void:
	var dialogue_choices: Array[DialogueData] = []
	# Dialogue with the highest amount of character triggers met will always be used.
	var highest_trigger: int = 0
	
	# Get all the characters that are in the game if we don't have it already.
	if _player_character_set.is_empty():
		for data: Dictionary in GameState.players.values():
			_player_character_set[data["character"]] = true
	
	for dialogue: DialogueData in _dialogue:
		var can_add: bool = true
		var trigger_count: int = 0
		
		# See if all conditions to play this dialogue are present in the input conditions. 
		if dialogue.play_conditions.all(func(required_condition): 
				return required_condition in conditions
		):
			# See if all characters in the dialogue are present in the game.
			for character: Constants.Character in dialogue.get_characters():
				if not _player_character_set.has(character) and character != Constants.Character.NONE:
					can_add = false
					break
				elif character != Constants.Character.NONE:
					trigger_count += 1
		else:
			can_add = false
		
		# Only add dialogues for which the most characters in the dialogue are present in the game.
		if can_add:
			if trigger_count > highest_trigger:
				highest_trigger = trigger_count
				dialogue_choices.clear() # Only use the dialogue with most triggers met
				dialogue_choices.append(dialogue)
			elif trigger_count == highest_trigger:
				dialogue_choices.append(dialogue)
	
	if len(dialogue_choices) <= 0:
		return
	
	_run_dialogue.rpc(_dialogue_paths[dialogue_choices.pick_random()])


## Play a full dialogue sequence. Should only be called via RPC by the server.
@rpc("any_peer", "call_local", "reliable")
func _run_dialogue(dialogue_data_path: String) -> void:
	_running_dialogue = load(dialogue_data_path)
	_running_dialogue_index = 0
	_dialogue_timer = 0.0


## Display a new line of dialogue.
func _show_line(line: DialogueLine) -> void:
	var dialogue_line_container: DialogueLineContainer = _dialogue_line_container.instantiate()
	
	dialogue_line_container.set_up(line)
	add_child(dialogue_line_container, true)
	_dialogue_timer = len(line.dialogue) * PER_CHARACTER_LINE_WAIT + BASE_LINE_WAIT
	
	if get_child_count() > MAX_LINES:
		_delete_oldest_child()


## Calls function to remove the oldest DialogueLineContainer.
func _delete_oldest_child() -> void:
	for child: Node in get_children():
		if child is DialogueLineContainer and not child.get_is_being_removed():
			child.delete()
			break
