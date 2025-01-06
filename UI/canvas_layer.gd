extends CanvasLayer

@export var _game_over_screen: Control = null
var textures: Array
var votes_to_retry: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textures.append($Abilities/Panel/TextureRect)
	textures.append($Abilities/Panel2/TextureRect)
	textures.append($Abilities/Panel3/TextureRect)
	textures.append($Abilities/Panel4/TextureRect)
	textures.append($Abilities/Panel5/TextureRect)
	
	$ExperienceBar.value = 0.0
	
	# Game over screen visibility
	GameState.game_over.connect(func():
		_game_over_screen.show()
	)
	_game_over_screen.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_character_body_2d_gained_experience(experience: float, level: int) -> void:
	$ExperienceBar.value = experience
	$LevelLabel.text = "Level: " + str(level)


func _on_character_body_2d_took_damage(health:int, health_max:int) -> void:
	$HealthBar/HealthLabel.text = str(health) + "/" + str(health_max)
	$HealthBar.value = float(health) / health_max


func _on_powerup_picked_up_powerup(sprite: Variant) -> void:
	for i in range(0, 5):
		if textures[i].texture == null:
			textures[i].texture = sprite
			return


func _on_retry_button_toggled(toggled_on: bool) -> void:
	if not multiplayer.is_server():
		_update_retry_votes.rpc_id(1, toggled_on)
	else:
		_update_retry_votes(toggled_on)


func _on_lobby_button_down() -> void:
	print("Go to lobby")
	# TODO: RPC all players. Unload the current map and show the lobby screen.


func _on_quit_button_down() -> void:
	print("Go to main menu")
	# TODO: RPC all other players. Unload the current map and show the lobby.
	# This player is shown the main menu and disconnects from the lobby.


# Only call on the server. Update count of how many players want to restart the game. 
# Reloads as soon as everyone votes to start again.
@rpc("any_peer", "call_remote")
func _update_retry_votes(voting_retry: bool) -> void:
	# TODO: Add counter showing how many votes there are
	if multiplayer.get_unique_id() != 1:
		return
	
	if voting_retry:
		votes_to_retry += 1
		if votes_to_retry >= GameState.connected_players:
			votes_to_retry = 0
			GameState.restart_game.rpc()
	else:
		votes_to_retry = max(0, votes_to_retry - 1)
	print(votes_to_retry, GameState.connected_players)
