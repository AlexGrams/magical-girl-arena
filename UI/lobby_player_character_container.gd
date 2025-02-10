class_name LobbyPlayerCharacterContainer
extends VBoxContainer
# Displays username, chosen character, and host status in the Lobby.

const character_animated_sprite: Resource = preload("res://UI/character_animated_sprite.tscn")

@export var id: Label = null
@export var username: Label = null
@export var character_sprite_location: Control = null

# The multiplayer ID of the player that this container represents
var player_id: int = 0
var sprite: Sprite2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().get_parent().get_parent().hidden.connect(func():
		if sprite != null and not sprite.is_queued_for_deletion():
			sprite.queue_free()
	)


# Set up this character container
func set_properties(
	new_username: String, 
	new_player_id: int, 
	character: Constants.Character
) -> void:
	
	username.text = new_username
	id.text = str(new_player_id)
	player_id = new_player_id
	
	# TODO: Set the sprite based off the character chosen
	if sprite != null and not sprite.is_queued_for_deletion():
		sprite.queue_free()
	
	sprite = character_animated_sprite.instantiate()
	get_tree().root.add_child.call_deferred(sprite, true)
	sprite.tree_entered.connect(func():
		sprite.global_position = character_sprite_location.global_position
		sprite.set_read_input(false)
		, CONNECT_ONE_SHOT
	)


# Remove all the displayed data for this container.
func clear_properties() -> void:
	username.text = ""
	id.text = ""
	if sprite != null and not sprite.is_queued_for_deletion():
		sprite.queue_free()


func _on_hidden() -> void:
	sprite.queue_free()
