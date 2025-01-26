extends CanvasLayer

@export var _game_over_screen: Control = null
# Parent of PlayerReadyIndicators representing how many players are ready to Retry.
@export var _retry_votes_container: Control = null
@export var _timer_text: Label = null
var textures: Array
var _votes_to_retry: int = 0
var _retry_indicators: Array[PlayerReadyIndicator]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textures.append($Abilities/Panel/TextureRect)
	textures.append($Abilities/Panel2/TextureRect)
	textures.append($Abilities/Panel3/TextureRect)
	textures.append($Abilities/Panel4/TextureRect)
	textures.append($Abilities/Panel5/TextureRect)
	
	$ExperienceBar.value = 0.0
	
	for retry_indicator in _retry_votes_container.get_children():
		_retry_indicators.append(retry_indicator)
	
	# Game over screen visibility
	GameState.game_over.connect(func():
		_game_over_screen.show()
		
		# Initialize the retry indicators
		var i = 0
		while i < GameState.connected_players:
			_retry_indicators[i].set_is_ready(false)
			i += 1
		while i < GameState.MAX_PLAYERS:
			_retry_indicators[i].hide()
			i += 1
	)
	_game_over_screen.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_timer_text.text = (
		"%02d:%02d" % [int(ceil(GameState.time)) / 60.0, int(ceil(GameState.time)) % 60]
	)


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


# This player is voting to retry the game.
func _on_retry_button_toggled(toggled_on: bool) -> void:
	_update_retry_votes.rpc(toggled_on)


# If any person goes back to the lobby, then all players are taken back.
func _on_lobby_button_down() -> void:
	# Wait for the next frame before quitting the game. Otherwise, an error is caused by
	# calling the "button down" signal on the same frame that the Playground is freed
	# (the Playground is an ancestor of the button).
	await get_tree().process_frame
	
	_return_to_lobby.rpc()


func _on_quit_button_down() -> void:
	GameState.quit_game.rpc(multiplayer.get_unique_id())


# Update count of how many players want to restart the game. 
# Reloads as soon as everyone votes to start again.
@rpc("any_peer", "call_local")
func _update_retry_votes(voting_retry: bool) -> void:
	if voting_retry:
		_votes_to_retry += 1
		if multiplayer.get_unique_id() == 1 and _votes_to_retry >= GameState.connected_players:
			_votes_to_retry = 0
			
			var world_tree_exited: Signal = GameState.world.tree_exited
			GameState.end_game.rpc()
			await world_tree_exited
			
			# start_game calls its own RPCs on all players so that they load the game as well.
			GameState.start_game()
	else:
		_votes_to_retry = max(0, _votes_to_retry - 1)
	
	# Update the indicators to display how many players want to retry.
	var i = 0
	while i < _votes_to_retry:
		_retry_indicators[i].set_is_ready(true)
		i += 1
	while i < GameState.connected_players:
		_retry_indicators[i].set_is_ready(false)
		i += 1
	while i < GameState.MAX_PLAYERS:
		_retry_indicators[i].hide()
		i += 1


# Unloads the Playground and shows the lobby.
@rpc("any_peer", "call_local")
func _return_to_lobby():
	var main_menu: MainMenu = get_tree().get_root().get_node(GameState.main_menu_node_path)
	
	GameState.end_game()
	main_menu.show()
	main_menu.refresh_lobby()
