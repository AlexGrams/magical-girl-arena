class_name LobbyPlayerCharacterContainer
extends VBoxContainer
# Displays username, chosen character, and host status in the Lobby.

const character_animated_sprite: Resource = preload("res://UI/character_animated_sprite.tscn")

@export var _username: Label = null
@export var _character_sprite_location: Control = null
@export var _portal_open: TextureRect = null
@export var _portal_closed: TextureRect = null
@export var _kick_button: Button = null

# The multiplayer ID of the player that this container represents
var player_id: int = 0
var sprite: CharacterAnimatedSprite2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().get_parent().get_parent().hidden.connect(func():
		if sprite != null and not sprite.is_queued_for_deletion():
			sprite.queue_free()
	)


func _process(_delta) -> void:
	# Something could happen where the character_sprite_location isn't at the right spot when
	# the sprite is added to the tree, so do this to ensure the sprite is where it should be.
	if sprite != null:
		sprite.global_position = _character_sprite_location.global_position


# Set up this character container
func set_properties(
	new_username: String, 
	new_player_id: int, 
	character: Constants.Character
) -> void:
	
	update_username_text(new_username)
	player_id = new_player_id
	_portal_closed.hide()
	_portal_open.show()
	
	if sprite == null:
		sprite = character_animated_sprite.instantiate()
		get_tree().root.add_child.call_deferred(sprite, true)
		sprite.tree_entered.connect(func():
			sprite.global_position = _character_sprite_location.global_position
			sprite.set_read_input(false)
			, CONNECT_ONE_SHOT
		)
	sprite.set_character(character)
	sprite.set_model_scale(1.5)
	
	# Button to kick player is only visible to the host, and only appears under other player characters.
	if multiplayer.get_unique_id() == 1 and new_player_id != 1:
		_kick_button.show()
	else:
		_kick_button.hide()


# Remove all the displayed data for this container.
func clear_properties() -> void:
	update_username_text("")
	_portal_open.hide()
	_portal_closed.show()
	if sprite != null and not sprite.is_queued_for_deletion():
		sprite.queue_free()
	_kick_button.hide()


func _on_hidden() -> void:
	if sprite != null and not sprite.is_queued_for_deletion():
		sprite.queue_free()

func update_username_text(new_text:String) -> void:
	# Updates the outline and shadow of the text as well.
	# Outline and shadow are necessary since regular outline results in gaps
	_username.text = new_text
	for child in _username.get_children():
		child.text = new_text


## Clicking on a portal brings up a Steam overlay to invite a friend that's online.
func _on_invite_friend_button_down() -> void:
	Steam.activateGameOverlayInviteDialog(GameState.lobby_id)


## Remove this player from the lobby.
func _on_kick_button_down() -> void:
	get_tree().root.get_node("MainMenu").leave_lobby.rpc_id(player_id)
