class_name DialogueLineContainer
extends Control
## Displays a line of dialogue with a speaker portrait.

## Image of who is speaking.
@export var _portrait: TextureRect = null
## Dialogue text.
@export var _text: Label = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Set the properties of this container.
func set_up(line: DialogueLine) -> void:
	_text.text = line.dialogue
	_portrait.texture = load(Constants.CHARACTER_DATA[line.speaker].icon_uid)


## Get rid of this dialogue line.
func delete() -> void:
	# TODO: Maybe play a fade out animation?
	queue_free()
