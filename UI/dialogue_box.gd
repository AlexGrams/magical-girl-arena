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
var _dialogue_line_container: PackedScene = preload("res://UI/dialogue_line_container.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for dialogue_data_path: String in DirAccess.open(DIALOGUE_DATA_FOLDER_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in dialogue_data_path:
			dialogue_data_path = dialogue_data_path.trim_suffix('.remap')
		
		var dialogue_data: DialogueData = ResourceLoader.load(DIALOGUE_DATA_FOLDER_PATH + dialogue_data_path)
		if not _dialogue.has(dialogue_data.play_trigger):
			_dialogue[dialogue_data.play_trigger] = []
		_dialogue[dialogue_data.play_trigger].append(dialogue_data)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Display a new line of dialogue.
func _show_line(line: DialogueLine) -> void:
	var dialogue_line_container: DialogueLineContainer = _dialogue_line_container.instantiate()
	dialogue_line_container.set_up(line)
	add_child(dialogue_line_container, true)
