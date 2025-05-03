class_name PlayerReadyIndicator
extends Panel


@export var _character_data_map := {}
@export var _not_ready_image: TextureRect = null
@export var _ready_image: TextureRect = null

var _is_ready = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_is_ready(new_is_ready: bool) -> void:
	if new_is_ready == _is_ready:
		return
	
	_is_ready = new_is_ready
	
	if _is_ready:
		_not_ready_image.hide()
		_ready_image.show()
	else:
		_not_ready_image.show()
		_ready_image.hide()


## Set which character icon is displayed on this indicator.
func set_sprite(character: Constants.Character) -> void:
	var data: CharacterData = load(_character_data_map[character])
	var image: Texture2D = load(data.icon_uid)
	
	_not_ready_image.texture = image
	_ready_image.texture = image
