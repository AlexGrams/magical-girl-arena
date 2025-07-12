class_name DialogueLineContainer
extends Control
## Displays a line of dialogue with a speaker portrait.


## Image of who is speaking.
@export var _portrait: TextureRect = null
## Speaker background
@export var _portrait_bg: TextureRect = null
## Dialogue text.
@export var _text: Label = null

## Tracks if line is already in the middle of being deleted
var _is_being_removed: bool = false


func get_is_being_removed() -> bool:
	return _is_being_removed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get current minimum sizes
	var text_size = _text.custom_minimum_size
	var portrait_bg_size = _portrait_bg.custom_minimum_size
	var portrait_size = _portrait.custom_minimum_size
	var full_size = size
	var full_scale = scale
	
	# Start all sizes at 0
	_text.custom_minimum_size = Vector2.ZERO
	_portrait_bg.custom_minimum_size = Vector2.ZERO
	_portrait.custom_minimum_size = Vector2.ZERO
	size = Vector2.ZERO
	scale = Vector2.ZERO
	
	### Play animation
	var tween = create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", full_scale, 0.5)
	tween.tween_property(self, "custom_minimum_size", full_size, 0.5)
	tween.tween_property(_text, "scale", full_scale, 0.5)
	tween.tween_property(_text, "custom_minimum_size", text_size, 0.5)
	tween.tween_property(_portrait_bg, "scale", full_scale, 0.5)
	tween.tween_property(_portrait_bg, "custom_minimum_size", portrait_bg_size, 0.5)
	tween.tween_property(_portrait, "scale", full_scale, 0.5)
	tween.tween_property(_portrait, "custom_minimum_size", portrait_size, 0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Set the properties of this container.
func set_up(line: DialogueLine) -> void:
	_text.text = line.dialogue
	if line.speaker != Constants.Character.NONE:
		_portrait.texture = load(Constants.CHARACTER_DATA[line.speaker].icon_uid)
	else:
		_portrait.texture = line.optional_portrait


## Get rid of this dialogue line.
func delete() -> void:
	if !_is_being_removed:
		_is_being_removed = true
		## Play removing animation
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.5)
		# Remove after animation finishes
		tween.tween_callback(queue_free)
