class_name PlayerCharacterBody2D
extends CharacterBody2D

## How long this player has to wait before being able to be revived.
const TIME_BEFORE_PLAYER_CAN_BE_REVIVED: float = 5.0
## How long another player must spend reviving this player.
const TIME_TO_REVIVE: float = 3.0
## Index of the collision layer for players.
const PLAYER_COLLISION_LAYER: int = 4
## Index of the collision layer for players that have been downed.
const DOWNED_PLAYER_COLLISION_LAYER: int = 10
## The most number of different powerups that this player can have INCLUDING their base powerup.
const MAX_POWERUPS: int = 5
## The most number of different artifacts that this player can have.
const MAX_ARTIFACTS: int = 3
## How long temporary health stays on the player before going away.
const TEMP_HEALTH_LINGER_TIME: float = 5.0
## Time in seconds between health regen ticks.
const HEALTH_REGEN_INTERVAL: float = 5.0

@export var level_shoot_intervals:Array
@export var speed = 400
## The movement direction being inputted for this character.
@export var input_direction: Vector2 = Vector2.ZERO

@export var _camera: Camera2D = null
@export var _player_collision_area: Area2D = null
@export var _pickup_area: Area2D = null
@export var _revive_collision_area: Area2D = null
@export var _revive_progress_bar: TextureProgressBar = null
@export var _revive_progress_bar_2: TextureProgressBar = null
@export var _on_screen_notifier: VisibleOnScreenNotifier2D = null
@export var _character_animated_sprite: Sprite2D = null
@export var _nametag: Label = null
@export var _health_bar: TextureProgressBar = null
@export var _health_label: Label = null
@export var _temp_health_bar: Control = null
@export var _temp_health_label: Label = null
@export var _laser_holder: Node2D = null

## All Powerups that this player has.
var powerups: Array[Powerup] = []
## All Abilities that this player has.
## Index 0 is the ultimate, and higher indicies are the regular abilities.
var abilities: Array[Ability] = []
## All Artifacts that this player has.
var artifacts: Array[Artifact] = []
var shoot_timer = 0
var shoot_interval = 1
var level = 1
var experience = 0

var health_max: int = 100
var health: int = health_max
# True when the player is incapacitated.
var is_down := false
# How long the player has been downed for. When time is up, this player can be revived.
var down_timer: float = 0.0
var revive_timer: float = 0.0

## What character this player is.
var _character: Constants.Character
## Temporary HP that goes away after some time. Divided into segments that have their own
## duration and value. Temp health is used up from first added to latest added.
var _temp_health_segments: Array[StatusTempHealth] = []
## All status effects on this player.
var _statuses: Array[Status] = []
# How much health is recovered per health regen tick.
var _health_regen: float = 0.0
# How long until the next health regen tick.
var _health_regen_timer: float = 0.0
## If true, the next time health is brought to 0, set it to 1 instead.
var _prevent_death: bool = false
## If true, the player cannot take any damage.
var _is_invulnerable: bool = false
## For spectating. All the players in the game.
var _spectate_characters: Array[PlayerCharacterBody2D] = []
## Index of the character in _spectate_characters that the local player is currently spectating if they are down.
var _spectate_index: int = 0
## Starts as Permanent + bought rerolls. Decreases as player uses rerolls
var _current_rerolls: int = 0
## Temporary rerolls that only become available in rare situations
var _temp_rerolls: int = 0
## How many rerolls have been used this round (not including temp rerolls)
var _used_rerolls: int = 0
# Stat levels
var _stat_health: int = 1
var _stat_health_regen: int = 1
var _stat_speed: int = 1
var _stat_pickup_radius: int = 1
# TODO: Waiting for design of these stats.
#var _stat_damage: int = 1
#var _stat_ultimate_damage: int = 1
#var _stat_ultimate_charge_rate: int = 1

signal took_damage(health:int, health_max:int, temp_health: int)
signal gained_experience(experience: float, level: int)
## Called after an Item (either Powerup or Artifact) has been instantiated and added to this player.
signal upgrade_added()
## Called after a new Powerup has been instantiated and added to this player.
signal powerup_added(powerup: Powerup)
## Was saved from taking lethal damage because _prevent_death was true.
signal death_prevented()
signal died()
signal revived()


func get_player_collision_area() -> Area2D:
	return _player_collision_area


## Returns a Status object if it exists on this player, or null if it does not.
func get_status(status_name: String) -> Status:
	for status in _statuses:
		if status != null and status.get_status_name() == status_name:
			return status
	return null


## Returns the extra laser objects that are turned on for the Laser powerup signature.
func get_lasers() -> Array[Node]:
	return _laser_holder.get_children()


## The player's speed stat level.
func get_stat_speed() -> int:
	return _stat_speed


@rpc("authority", "call_local")
func _set_speed(new_speed: float) -> void:
	speed = new_speed


@rpc("authority", "call_local")
func set_prevent_death(value: bool) -> void:
	_prevent_death = value


func set_is_invulnerable(value: bool) -> void:
	_is_invulnerable = value


func set_ultimate_crit_chance(value: float) -> void:
	abilities[0].set_crit_chance(value)


## Disable or enabled the magnetic area to pick up items.
@rpc("any_peer", "call_local")
func set_exp_pickup_enabled(value: bool) -> void:
	_pickup_area.get_child(0).set_deferred("disabled", not value)


func _ready():
	_revive_collision_area.hide()
	
	# Setup rerolls
	_current_rerolls = GameState.rerolls + GameState.perm_rerolls
	## No longer using stats.
	#if is_multiplayer_authority():
		#$"../CanvasLayer".update_stats(self)


## Called when a Powerup is selected on the level up screen.
func _on_upgrade_chosen(itemdata: ItemData):
	if itemdata is PowerupData:
		upgrade_or_grant_powerup(itemdata, false)
	elif itemdata is ArtifactData:
		add_artifact(itemdata)
	
	upgrade_added.emit()


## Increases the level of a Powerup, or adds it to the player if they don't have it already.
func upgrade_or_grant_powerup(powerup_data: PowerupData, is_signature: bool = false) -> void:
	var powerup_found = false
	
	# Upgrade the chosen powerup if we already have it.
	for child in get_children():
		if child is Powerup and child.powerup_name == powerup_data.name:
			if child.current_level < child.max_level:
				child.level_up()
			if is_signature:
				child.set_is_signature(true)
			$"..".get_hud_canvas_layer().update_powerup_level(powerup_data, child.current_level)
			
			powerup_found = true
			break
	
	# If we don't have the chosen powerup, then add it to the player.
	if !powerup_found and len(powerups) < MAX_POWERUPS:
		add_powerup(powerup_data, is_signature)


## Adds an artifact to this player
func add_artifact(artifact_data: ArtifactData) -> void:
	var artifact: Artifact = artifact_data.scene.instantiate()
	artifact.set_artifactdata(artifact_data)
	add_child(artifact, true)
	artifacts.append(artifact)
	artifact.activate(self)
	
	# Add artifact sprite to UI
	$"../CanvasLayer".add_artifact(artifact_data)


## Returns which character this player is.
func get_character() -> Constants.Character:
	return _character


## Upgrade stats depending on which upgrade was chosen
func _on_stat_upgrade_chosen(stat_type: Constants.StatUpgrades) -> void:
	match stat_type:
		Constants.StatUpgrades.HEALTH:
			_stat_health += 1
			# TODO: Temporary for now. Figure out if we want to do this off a curve or something.
			_add_max_health.rpc(10)
		Constants.StatUpgrades.HEALTH_REGEN:
			_stat_health_regen += 1
			_add_health_regen.rpc(1.0)
		Constants.StatUpgrades.SPEED:
			_stat_speed += 1
			_set_speed.rpc(speed + 40)
		Constants.StatUpgrades.PICKUP_RADIUS:
			_stat_pickup_radius += 1
			_pickup_area.scale += Vector2(0.1, 0.1)
		#Constants.StatUpgrades.DAMAGE:
			#_stat_damage += 1
		#Constants.StatUpgrades.ULTIMATE_DAMAGE:
			#_stat_ultimate_damage += 1
		#Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
			#_stat_ultimate_charge_rate += 1
		_:
			push_error("No upgrade functionality for this stat upgrade type")


## Remove a stat upgrade level.
func decrement_stat(stat_type: Constants.StatUpgrades) -> void:
	match stat_type:
		Constants.StatUpgrades.HEALTH:
			push_error("Not implemented")
		Constants.StatUpgrades.HEALTH_REGEN:
			if _stat_health_regen > 1:
				_stat_health_regen -= 1
				_add_health_regen.rpc(-1.0)
		Constants.StatUpgrades.SPEED:
			if _stat_speed > 1:
				_stat_speed -= 1
				_set_speed.rpc(speed - 40)
		Constants.StatUpgrades.PICKUP_RADIUS:
			push_error("Not implemented")
		#Constants.StatUpgrades.DAMAGE:
			#_stat_damage += 1
		#Constants.StatUpgrades.ULTIMATE_DAMAGE:
			#_stat_ultimate_damage += 1
		#Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
			#_stat_ultimate_charge_rate += 1
		_:
			push_error("No upgrade functionality for this stat upgrade type")


## Returns the current level of a player's stat given the stat enum type.
func get_stat(stat_type: Constants.StatUpgrades) -> int:
	match stat_type:
		Constants.StatUpgrades.HEALTH:
			return _stat_health
		Constants.StatUpgrades.HEALTH_REGEN:
			return _stat_health_regen
		Constants.StatUpgrades.SPEED:
			return _stat_speed
		Constants.StatUpgrades.PICKUP_RADIUS:
			return _stat_pickup_radius
		#Constants.StatUpgrades.DAMAGE:
			#return _stat_damage
		#Constants.StatUpgrades.ULTIMATE_DAMAGE:
			#return _stat_ultimate_damage
		#Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
			#return _stat_ultimate_charge_rate
		_:
			push_error("No upgrade functionality for this stat upgrade type")
	return 1


func get_temp_health() -> int:
	var result: int = 0
	for segment: StatusTempHealth in _temp_health_segments:
		result += segment.value
	return result


func get_input():
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != null:
		velocity = input_direction * speed


## Controls for when in spectator mode
func get_spectator_input() -> void:
	if len(GameState.player_characters.values()) <= 1:
		return
	
	if Input.is_action_just_pressed("move_left"):
		_spectate_index -= 1
		if _spectate_index < 0:
			_spectate_index = len(_spectate_characters) - 1
		_spectate_characters[_spectate_index].make_camera_current()
		$"..".get_hud_canvas_layer().set_spectated_character(_spectate_index)
	elif Input.is_action_just_pressed("move_right"):
		_spectate_index = (_spectate_index + 1) % len(_spectate_characters)
		_spectate_characters[_spectate_index].make_camera_current()
		$"..".get_hud_canvas_layer().set_spectated_character(_spectate_index)


## Switches client's view to use this character's camera.
func make_camera_current() -> void:
	_camera.make_current()


func _process(delta: float) -> void:
	# Health regen - ticks at every interval, but does nothing if it ticks when health is full
	if _health_regen > 0.0:
		_health_regen_timer -= delta
		if _health_regen_timer <= 0.0:
			# Add health
			take_damage(-_health_regen)
			_health_regen_timer = HEALTH_REGEN_INTERVAL
	
	# Death and reviving
	if is_down:
		if down_timer < TIME_BEFORE_PLAYER_CAN_BE_REVIVED:
			down_timer += delta
			
			if down_timer >= TIME_BEFORE_PLAYER_CAN_BE_REVIVED:
				_revive_progress_bar.value = 1
			else:
				_revive_progress_bar.value = down_timer / TIME_BEFORE_PLAYER_CAN_BE_REVIVED
		elif revive_timer < TIME_TO_REVIVE:
			if _revive_collision_area.has_overlapping_areas():
				revive_timer += delta
				if revive_timer >= TIME_TO_REVIVE:
					revive()
			else:
				revive_timer = max(revive_timer - delta, 0.0)
			
			_revive_progress_bar_2.value = revive_timer / TIME_TO_REVIVE


func _physics_process(_delta):
	if is_multiplayer_authority():
		if not is_down:
			get_input()
			move_and_slide()
		else:
			get_spectator_input()
	else:
		# For characters owned by other clients, use input direction to predict their movement,
		# making it seem smoother. input_direction is replicated using the MultiplayerSynchronizer.
		if not is_down:
			velocity = input_direction * speed
			move_and_slide()


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if is_down:
		return
	
	if event.is_action_pressed("ability_ultimate") and abilities[0].get_can_activate():
		abilities[0].activate()
		
		# Analytics: Record ult activation
		Analytics.add_ult_count()
	
	# Cheats
	if not OS.has_feature("release"):
		if event is InputEventKey and event.pressed:
			# Level up
			if event.keycode == KEY_KP_1:
				GameState.collect_exp.rpc(GameState.exp_for_next_level - GameState.experience)
			# Add Powerup cheat screen
			if event.keycode == KEY_KP_2:
				GameState.playground.hud_canvas_layer.upgrade_any_screen.toggle_cheat()
			# Die
			if event.keycode == KEY_KP_3:
				kill()


func get_rerolls() -> int:
	return _current_rerolls + _temp_rerolls


func increment_temp_rerolls() -> void:
	_temp_rerolls += 1


func decrement_rerolls() -> void:
	if _temp_rerolls > 0:
		_temp_rerolls -= 1
	else:
		# Decide whether a permanent or bought reroll was used
		# Permanent rerolls are used FIRST
		_used_rerolls += 1
		if _used_rerolls > GameState.perm_rerolls:
			GameState.rerolls -= 1
		_current_rerolls -= 1
		SaveManager.save_game()


# Gives this player a new powerup.
func add_powerup(powerup_data: PowerupData, is_signature: bool = false):
	var powerup: Powerup = powerup_data.scene.instantiate()
	powerup.set_authority(multiplayer.get_unique_id())
	powerup.is_signature = is_signature
	powerup.set_powerup_index(len(powerups))
	add_child(powerup, true)
	powerups.append(powerup)
	
	# Show the icon for this powerup on the HUD
	$"..".get_hud_canvas_layer().add_powerup(powerup_data)
	
	if not is_down:
		powerup.activate_powerup()
	
	powerup_added.emit(powerup)


# Enable all equipped powerups.
func enable_powerups():
	for powerup: Powerup in powerups:
		powerup.activate_powerup()


# Deactivate all equipped powerups.
func disable_powerups():
	for powerup: Powerup in powerups:
		powerup.deactivate_powerup()


## Changes ultimate cooldown time by a percentage.
func scale_ultimate_cooldown(percent: float) -> void:
	abilities[0].current_cooldown_time *= percent
	abilities[0].cooldown *= percent


# Deal damage to the player.
@rpc("authority", "call_local")
func take_damage(damage: float) -> void:
	if is_down or not is_multiplayer_authority() or _is_invulnerable:
		return
	
	# Deplete temp health before regular health.
	# Skip this if the player is gaining health instead.
	if damage > 0:
		while len(_temp_health_segments) > 0 and damage > 0:
			if _temp_health_segments[0].value > damage:
				# Damage doesn't fully deplete the first segment.
				_temp_health_segments[0].value -= int(damage)
				damage = 0
			else:
				# Damage depletes the first segment and carries onto subsequent segments.
				damage -= _temp_health_segments[0].value
				_temp_health_segments[0].queue_free()
				_temp_health_segments.pop_front()
	
	health = clamp(health - damage, 0, health_max)
	took_damage.emit(health, health_max, get_temp_health())
	
	if damage > 0:
		$AnimationPlayer.play("took_damage")
		
		# Death
		if health <= 0:
			if _prevent_death:
				health = 1
				_prevent_death = false
				death_prevented.emit()
			elif is_multiplayer_authority():
				die.rpc()


## Emit the took_damage signal on this client's replication of this character with certain arguments.
@rpc("authority", "call_remote")
func _emit_took_damage(new_health, new_health_max, new_temp_health) -> void:
	# Sort of a hack to get the "take damage" animation to play on all clients
	if new_health < health:
		$AnimationPlayer.play("took_damage")
	
	health = new_health
	health_max = new_health_max
	took_damage.emit(new_health, new_health_max, new_temp_health)


## Changes the health bar and temp health bar displayed under this character.
func _update_health_bar(_new_health, _new_health_max, _new_temp_health) -> void:
	_health_label.text = str(health) + "/" + str(health_max)
	_health_bar.value = (float(health) / float(health_max)) * 100
	
	var temp_health: int = get_temp_health()
	if temp_health > 0:
		_temp_health_bar.show()
		_temp_health_label.text = str(temp_health)
	else:
		_temp_health_bar.hide()


## Increases this player's max health, which also increases their current health value by the same amount.
@rpc("authority", "call_local")
func _add_max_health(max_health_to_add: int) -> void:
	health_max += max_health_to_add
	take_damage(-max_health_to_add)


## Increases this player's health regen.
@rpc("authority", "call_local")
func _add_health_regen(health_regen_to_add: float) -> void:
	_health_regen += health_regen_to_add


## Add temporary health to the player by creating a new temp HP segment.
@rpc("any_peer", "call_local")
func add_temp_health(temp_health_to_add: int, _duration: float = TEMP_HEALTH_LINGER_TIME) -> void:
	if is_down: 
		return
	
	var new_segment: StatusTempHealth = StatusTempHealth.new()
	
	new_segment.duration = _duration
	new_segment.value = temp_health_to_add
	_temp_health_segments.append(new_segment)
	new_segment.expired.connect(func():
		_temp_health_segments.remove_at(_temp_health_segments.find(new_segment))
		took_damage.emit(health, health_max, get_temp_health())
	)
	add_child(new_segment)
	
	took_damage.emit(health, health_max, get_temp_health())


## Apply a status effect to this player.
func add_status(status: Status) -> void:
	_statuses.append(status)
	add_child(status)
	status.activate()


func remove_status(status: Status) -> void:
	var index: int = _statuses.find(status)
	if index != -1:
		_statuses.remove_at(index)


## Deplete all of this player's health and temp health.
func kill():
	var damage: float = health
	for segment: StatusTempHealth in _temp_health_segments:
		damage += segment.value
	take_damage(damage)


# The player becomes incapacitated. Their abilities no longer work, and they must wait some
# time before being able to be revived by another player. If no players remain, then the
# game is over.
@rpc("authority", "call_local")
func die():
	is_down = true
	down_timer = 0.0
	revive_timer = 0.0
	_revive_progress_bar.value = 0
	_revive_progress_bar_2.value = 0
	_revive_collision_area.show()
	_player_collision_area.set_collision_layer_value(PLAYER_COLLISION_LAYER, false)
	_player_collision_area.set_collision_layer_value(DOWNED_PLAYER_COLLISION_LAYER, true)
	_character_animated_sprite.play_death_animation()
	
	if is_multiplayer_authority():
		Analytics.add_death_time(int(GameState.time))
		_setup_spectator_mode()
	
	disable_powerups()
	died.emit()


# The player has been picked back up by another player.
func revive():
	is_down = false
	_revive_collision_area.hide()
	_player_collision_area.set_collision_layer_value(PLAYER_COLLISION_LAYER, true)
	_player_collision_area.set_collision_layer_value(DOWNED_PLAYER_COLLISION_LAYER, false)
	take_damage(-health_max)
	_character_animated_sprite.play_revive_animation()
	
	if is_multiplayer_authority():
		make_camera_current()
		$"..".get_hud_canvas_layer().hide_spectator_mode()
	
	enable_powerups()
	revived.emit()


## Set up UI and controls so that the local player can spectate other players.
func _setup_spectator_mode() -> void:
	_spectate_characters.clear()
	for character: PlayerCharacterBody2D in GameState.player_characters.values():
		if character == self:
			_spectate_index = len(_spectate_characters)
		_spectate_characters.append(character)
	
	GameState.playground.hud_canvas_layer.setup_spectator_mode(_spectate_characters, _spectate_index)


## Set the name that appears above this character.
@rpc("authority", "call_local")
func set_nametag(new_name: String) -> void:
	_nametag.text = new_name


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	# NOTE: Only clients have authority over when they take damage.
	# The client takes damage only when they see themselves hit an enemy on their screen.
	# This means the server doesn't have authority over when anyone else takes damage.
	# take_damage needs to be RPC'd on all clients to help synchronize living/dead state.
	# Some side effects include:
	# - Multiple players can take damage from the same projectile if it isn't destroyed
	#   on time.
	# - Clients can see another player not take damage from an enemy, despite them touching
	#   on their screen. This is because the other player didn't hit the enemy from their
	#   POV, so the collision didn't happen.
	
	if area.get_collision_layer_value(2): #If Enemy
		pass
		#take_damage.rpc(10)
	elif area.get_collision_layer_value(6): #If Enemy Bullet:
		take_damage.rpc(area.damage)
		if area.get_parent() != null and area.get_parent().has_method("request_delete"):
			area.get_parent().request_delete.rpc_id(1)


# Tells this client's GameState which ID goes with which local player node instance.
@rpc("any_peer", "call_local")
func register_with_game_state(owning_player_id: int) -> void:
	GameState.add_player_character(owning_player_id, self)


# Sets up this character after it is spawned. Has different behavior depending on if this
# function is called on the character this client controls. 
# Should be called only once, like with _ready().
@rpc("any_peer", "call_local")
func ready_player_character(character: Constants.Character) -> void:
	# Set the character's appearance
	_character = character
	var character_data: CharacterData = Constants.CHARACTER_DATA[character]
	if character_data == null:
		push_error("Character data not mapped!")
	
	_character_animated_sprite.set_character(character)
	
	# Signal for health changes
	took_damage.connect(_update_health_bar)
	took_damage.emit(health, health_max, get_temp_health())
	
	# Should not be called on characters that are not owned by this game instance.
	if is_multiplayer_authority():
		# Analytics: record this client's character
		Analytics.set_character(character_data.name)
		
		# Signal for experience changes
		gained_experience.connect($"../CanvasLayer"._on_character_body_2d_gained_experience)
		
		# Powerup upgrade buttons
		$"../CanvasLayer/UpgradeScreenPanel".upgrade_chosen.connect(_on_upgrade_chosen)
		# Stat upgrade buttons
		$"../CanvasLayer/UpgradeScreenPanel".stat_upgrade_chosen.connect(_on_stat_upgrade_chosen)
		
		# Give the player the basic shoot powerup.
		# Only the character that this player controls is given the ability. 
		var base_powerup_data: PowerupData = load(character_data.base_powerup_data) 
		add_powerup(base_powerup_data, true)
		
		# Set up ultimate ability
		var ult: Ability = load(character_data.ultimate_ability).instantiate()
		ult.set_authority(multiplayer.get_unique_id())
		add_child(ult)
		abilities.append(ult)
		$"..".get_hud_canvas_layer().set_up_ultimate_ui(character_data, ult)
		
		# Every time our health updates, signal on the other clients what the new healh values are.
		took_damage.connect(func(new_health, new_health_max, new_temp_health):
			_emit_took_damage.rpc(new_health, new_health_max, new_temp_health)
		)
	else:
		# This client does not own this PlayerCharacter. Connect events to show the
		# pointer to this character when it goes off screen for the local client.
		get_tree().root.get_node("Playground/CanvasLayer").add_character_to_point_to(_on_screen_notifier)
	
	# NOTE: Put player-related testing functionality here.


@rpc("any_peer", "call_local")
func teleport(new_position: Vector2) -> void:
	self.position = new_position


# Sets multiplayer authority and other values for this character.
@rpc("any_peer", "call_local")
func setup_authority(id: int, character: Constants.Character) -> void:
	# TODO: There might be a bug that happens if this funciton is called before the character enters
	# the tree. Need to test.
	set_multiplayer_authority(id)
	ready_player_character(character)
	
	# Extra functionality if this client is being given authority to its own character.
	if id == multiplayer.get_unique_id():
		make_camera_current()
		
		# Sort of jank, but we notify all other client's about this character's nametag here.
		if GameState.USING_GODOT_STEAM:
			set_nametag.rpc(Steam.getPersonaName())


# Emits the signal for gaining experience on all clients.
@rpc("any_peer", "call_local")
func emit_gained_experience(new_experience: float, new_level: int):
	if not is_multiplayer_authority():
		return
	
	experience = new_experience
	level = new_level
	
	gained_experience.emit(float(experience) / GameState.exp_for_next_level, level)


## Causes all pickups on the field to magnetize towards this player.
@rpc("any_peer", "call_local")
func collect_all_pickups() -> void:
	for pickup: EXPOrb in get_tree().get_nodes_in_group("pickup"):
		pickup.set_player(get_path())


## Causes EXP and Gold orbs to gravitate towards the player when they enter this area.
func _on_exp_pickup_area_2d_area_entered(area: Area2D) -> void:
	if multiplayer.is_server() and area.get_collision_layer_value(3):
		var parent: EXPOrb = area.get_parent()
		if parent is not HealthOrb:
			parent.set_player.rpc(self.get_path())


## Called when this character levels up, but before they select their next upgrade.
func level_up(new_level: int) -> void:
	abilities[0].update_damage(new_level)


## RPC the server to spawn in a pet owned by this character.
@rpc("any_peer", "call_local")
func spawn_pet_and_set_up(pet_scene: String, parent_path: String, starting_position: Vector2, damage: float, owner_id: int, powerup_index: int, pet_level: int) -> void:
	if multiplayer.get_unique_id() != 1:
		return
	
	var pet: BulletPet = load(pet_scene).instantiate()
	get_tree().root.get_node("Playground").add_child(pet, true)
	pet.set_up.rpc(parent_path, starting_position, damage, owner_id, powerup_index, pet_level)


## Shows the extra laser drones granted by the signature Laser powerup.
@rpc("authority", "call_local")
func show_lasers() -> void:
	for laser: Node in _laser_holder.get_children():
		laser.show()


## Hides the extra laser drones granted by the signature Laser powerup.
@rpc("authority", "call_local")
func hide_lasers() -> void:
	for laser: Node in _laser_holder.get_children():
		laser.hide()
