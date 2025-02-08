class_name LobbyPlayerCharacterContainer
extends VBoxContainer
# Displays username, chosen character, and host status in the Lobby.

const character_animated_sprite: Resource = preload("res://UI/character_animated_sprite.tscn")

@export var id: Label = null
@export var username: Label = null
@export var character_sprite_location: Control = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Set up this character container
func set_properties(
	new_username: String, 
	new_player_id: String, 
	character: Constants.Character
) -> void:
	
	username.text = new_username
	id.text = new_player_id
	
	# TODO: Set the sprite based off the character chosen
	
	var sprite: Sprite2D = character_animated_sprite.instantiate()
	get_tree().root.add_child.call_deferred(sprite)
	sprite.tree_entered.connect(func():
		sprite.global_position = character_sprite_location.global_position
		sprite.set_read_input(false)
		, CONNECT_ONE_SHOT
	)


# Remove all the displayed data for this container.
func clear_properties() -> void:
	username.text = ""
	id.text = ""
