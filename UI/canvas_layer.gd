class_name HUDCanvasLayer
extends CanvasLayer

@export var _game_over_screen: GameOverScreen = null
# Parent of PlayerReadyIndicators representing how many players are ready to Retry.
@export var _retry_votes_container: Control = null
@export var _timer_text: Label = null
@export var _pointer_parent: Control = null
## Parent of panels displaying each powerup
@export var _powerup_container: Container = null
## Displays the icon for the player's ultimate ability.
@export var _ultimate_texture: TextureRect = null
## Displays the cooldown for the player's ultimate ability.
@export var _ultimate_progress_bar: ProgressBar = null
## Displays the player's current stat levels.
@export var _stat_level_container: Control = null
## Only appears if the player has temp health
@export var _temp_health_control: Control = null
## Displays how much temp health the player has
@export var _temp_health_text: Label = null
## Health bar for bosses.
@export var _boss_health_bar: ProgressBar = null
## Text displaying boss health.
@export var _boss_health_text: Label = null

# TODO: Testing
var fraction: float = 0.0

## Images indicating each powerup
var _powerup_textures: Array[TextureRect] = []
## Text displaying each powerup level
var _powerup_level_text: Array[Label] = []
var _votes_to_retry: int = 0
var _retry_indicators: Array[PlayerReadyIndicator]
var _pointers: Array[TextureRect] = []
## Maps Powerup name to which index its UI components are in _powerup_level_text
## and _powerup_textures.
var _powerup_display_index = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_boss_health_bar.hide()
	
	for pointer in _pointer_parent.get_children():
		_pointers.append(pointer)
		
	for powerup_panel: Control in _powerup_container.get_children():
		_powerup_textures.append(powerup_panel.find_child("Powerup_Image"))
		_powerup_level_text.append(powerup_panel.find_child("Powerup_Level_Label"))
		_powerup_level_text[-1].text = ""
	
	$ExperienceBar.value = 0.0
	
	# Game over screen visibility
	GameState.game_over.connect(func(has_won_game):
		_game_over_screen.set_up(has_won_game)
		
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
	
	for retry_indicator in _retry_votes_container.get_children():
		_retry_indicators.append(retry_indicator)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_timer_text.text = (
		"%02d:%02d" % [int(ceil(GameState.time)) / 60.0, int(ceil(GameState.time)) % 60]
	)
	
	# Update pointers that indicate the direction of players not on the screen.
	var used_pointers: int = 0
	for id: int in GameState.player_characters:
		var node: Node2D = GameState.player_characters[id]
		if (
			id == multiplayer.get_unique_id() or 
			node == null or 
			GameState.get_local_player() == null or 
			node.find_child("VisibleOnScreenNotifier2D").is_on_screen()
		):
			continue
		
		var _pointer = _pointers[used_pointers]
		_pointer.show()
		used_pointers += 1
		
		# The angle in radians from the local player to the other player character
		var angle_to_other_player: float = (
			(node.position - GameState.get_local_player().position).angle()
		)
		
		var screen_x = get_viewport().get_visible_rect().size.x
		var screen_y = get_viewport().get_visible_rect().size.y
		var pointer_size_x = _pointer.size.x
		var pointer_size_y = _pointer.size.y
		
		# Since the tangent function used to calculate the arrow's position is discontinuous at 
		# +/- PI/2, we need two different equations for setting the y-position of the pointer.
		if angle_to_other_player >= -PI / 2 and angle_to_other_player <= PI / 2:
			_pointer.set_position(Vector2(
				clamp((0.5 * screen_y) / tan(abs(angle_to_other_player)) + (0.5 * screen_x), 0.0, screen_x - pointer_size_x),
				clamp((0.5 * screen_x) * tan(angle_to_other_player) + (0.5 * screen_y), 0.0, screen_y - pointer_size_y)
			))
		else:
			_pointer.set_position(Vector2(
				clamp((0.5 * screen_y) / tan(abs(angle_to_other_player)) + (0.5 * screen_x), 0.0, screen_x - pointer_size_x),
				clamp((0.5 * screen_x) * tan(PI - angle_to_other_player) + (0.5 * screen_y), 0.0, screen_y - pointer_size_y)
			))
		
		_pointer.rotation = angle_to_other_player + PI / 2
	
	while used_pointers < len(_pointers):
		_pointers[used_pointers].hide()
		used_pointers += 1


func _on_character_body_2d_gained_experience(experience: float, level: int) -> void:
	$ExperienceBar.value = experience
	$LevelLabel.text = "Level: " + str(level)


func _on_character_body_2d_took_damage(health: int, health_max: int, temp_health: int) -> void:
	$HealthBar/HealthLabel.text = str(health) + "/" + str(health_max)
	$HealthBar.value = float(health) / health_max
	
	if temp_health > 0:
		_temp_health_control.show()
		_temp_health_text.text = str(temp_health)
	else:
		_temp_health_control.hide()


func _on_powerup_picked_up_powerup(sprite: Variant) -> void:
	for i in range(0, 5):
		if _powerup_textures[i].texture == null:
			_powerup_textures[i].texture = sprite
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


## Returns the Container for dislaying Powerup icons.
func get_powerup_container() -> Container:
	return _powerup_container


# Sets up the UI for the local player's ultimate ability. The icon updates depending on the ult cooldown.
func set_up_ultimate_ui(character_data: CharacterData, ultimate: Ability) -> void:
	_ultimate_texture.texture = character_data.ult_texture
	# Update progress bar fill percent and visibility.
	ultimate.cooldown_time_updated.connect(func(cooldown_time_remaining_fraction):
		_ultimate_progress_bar.value = cooldown_time_remaining_fraction
		if cooldown_time_remaining_fraction > 0:
			_ultimate_progress_bar.show()
		else:
			_ultimate_progress_bar.hide()
	)
	_ultimate_progress_bar.hide()


# TODO: Maybe make this event-based rather than checking every frame. Would then need a way to
# keep track of the object that each pointer is pointing to.
# Connects events to enable or disable arrows to offscreen players.
func add_character_to_point_to(notifier: VisibleOnScreenNotifier2D) -> void:
	notifier.screen_entered.connect(func():
		#notifier.is_on_screen()
		pass
	)
	
	notifier.screen_exited.connect(func():
		pass
	)


## Add a powerup icon and level indicator to the UI
func add_powerup(powerup_data: PowerupData) -> void:
	for i in range(len(_powerup_level_text)):
		if _powerup_level_text[i].text == "":
			# We consider a Powerup icon with no level to be an unset icon.
			_powerup_textures[i].texture = powerup_data.sprite
			_powerup_level_text[i].text = "1"
			_powerup_display_index[powerup_data.name] = i
			
			break


## Update the UI display for a Powerup's level
func update_powerup_level(powerup_data: PowerupData, new_level: int) -> void:
	if powerup_data.name not in _powerup_display_index:
		push_error("Powerup display name not stored in index map.")
		return
	
	_powerup_level_text[_powerup_display_index[powerup_data.name]].text = str(new_level)


## Updates the stat values on the UI.
func update_stats(player: PlayerCharacterBody2D) -> void:
	var stat_containers := _stat_level_container.get_children()
	
	stat_containers[0].set_stat_value(player._stat_health)
	stat_containers[1].set_stat_value(player._stat_health_regen)
	stat_containers[2].set_stat_value(player._stat_speed)
	stat_containers[3].set_stat_value(player._stat_pickup_radius)


## Display the boss health bar. Health percent = [0, 1].
@rpc("authority", "call_local")
func show_boss_health_bar(health_percent: float = 1.0) -> void:
	_boss_health_bar.show()
	update_boss_health_bar(health_percent)


## Hide the boss health bar.
@rpc("authority", "call_local")
func hide_boss_health_bar() -> void:
	_boss_health_bar.hide()


## Update fill and value shown on the Boss health bar. Health percent = [0, 1].
@rpc("authority", "call_local")
func update_boss_health_bar(health_percent: float) -> void:
	_boss_health_bar.value = health_percent
	_boss_health_text.text = str(ceil(health_percent * 100.0)) + "%"
