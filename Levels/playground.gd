class_name Playground
extends Node2D
## Script for controlling events that occur during gameplay.


## Time in seconds before we stop waiting for all clients to tell the Playground if it can spawn
## the Powerup Pickup. Powerup is spawned when time expires.
const _POWERUP_POOLING_TIMEOUT: float = 3.0
## How many DamageIndicators are spawned in our object pool.
const _DAMAGE_INDICATOR_POOL_SIZE: int = 200
## How many BulletLightningArc objects are in the pool.
const _LIGHTNING_ARC_POOL_SIZE: int = 150

@onready var exp_scene = preload("res://Pickups/exp_orb.tscn")
@onready var gold_scene = preload("res://Pickups/gold.tscn")

## List of events describing what enemies to spawn, when to spawn them, and how many to spawn.
@export var spawn_events: Array[EnemySpawnEventData] = []
## Time in seconds from the start of the game, expressed as a ratio between the elapsed game 
## time and the total game time, at which the corrupted magical girl enemy spawns. 0.0 is at the 
## start of the game, and 1.0 is at the end of the game timer.
@export var corrupted_enemy_spawn_time_fraction: float = 0.0
## Maps character name to the resource file of that character's corrupted Enemy object.
@export var corrupted_enemy_choices := {} 
## List of possible EnemyBoss scenes that can spawn at the end of the game.
@export var boss_choices: Array[PackedScene] = []
## The name of the boolean variable in GameState that is set to "true" when the players
## beat this map.
@export var map_win_save_variable_name: String = ""
## Spawners around the map that create enemies from spawn events. 
@export var regular_enemy_spawners: Array[EnemySpawner] = []
## The EnemySpawner for spawning the corrupted magical girl.
@export var corrupted_enemy_spawner: EnemySpawner = null
## The HUD for the local player
@export var hud_canvas_layer: HUDCanvasLayer = null
## The bullet spawner on this Playground
@export var bullet_spawner: BulletSpawner = null
## Light to create darkness when boss spawns
@export var point_light: BossPointLight2D = null

## Path to this map's MapData resource file.
@export var _map_data_path: String = ""
## Path to the DamageIndicator scene.
@export var _damage_indicator_scene: String = ""
@export var _lightning_arc_scene: String = ""
## Animation to play when the boss spawns
@export var boss_animation: PackedScene = preload("res://Sprites/Enemy/Corvus_Summoning_Animation.tscn")
## Sound effect to play when boss spawns
@export var boss_sfx: SoundEffectSettings.SOUND_EFFECT_TYPE

## Sound effect to play for walking noises
@export var walking_sfx: SoundEffectSettings.SOUND_EFFECT_TYPE

## The relative liklihoods of dropping EXP, gold, or nothing when an Enemy dies.
var drop_weight_exp: float = 15.0
var drop_weight_gold: float = 4.0
var drop_weight_nothing: float = 1.0

## The dialogue condition specfic to this map.
var _map_dialogue_condition: Constants.DialoguePlayCondition
var _has_corrupted_enemy_spawned := false
var _has_boss_spawned := false

## The upcoming spawn event to process.
var _current_spawn_event: int = 0

## Object pool of damage indicators.
var _damage_indicator_pool: Array[DamageIndicator] = []
## Index of next damage indicator to be used from the pool.
var _damage_indicator_index: int = 0
## Lightning arc bullet object pool
var _lightning_arc_pool: Array[BulletLightningArc] = []
var _lightning_arc_index: int = 0


func get_hud_canvas_layer() -> HUDCanvasLayer:
	return hud_canvas_layer


func get_map_dialogue_condition() -> Constants.DialoguePlayCondition:
	return _map_dialogue_condition


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Show the loading screen while waiting for the other players to load in.
	hud_canvas_layer.show_loading_screen()
	GameState.unpaused.connect(hud_canvas_layer.hide_loading_screen, CONNECT_ONE_SHOT)
	
	GameState.set_playground(self)
	GameState.client_game_loaded.rpc()
	
	# Map-specific DialoguePlayCondition
	_map_dialogue_condition = load(_map_data_path).map_dialogue_condition
	
	# Set up DamageIndicator pool
	var damage_indicator_resource: Resource = load(_damage_indicator_scene)
	for i in range(_DAMAGE_INDICATOR_POOL_SIZE):
		var damage_indicator: DamageIndicator = damage_indicator_resource.instantiate()
		add_child(damage_indicator, true)
		_damage_indicator_pool.append(damage_indicator)
	
	# Lightning arc object pool
	var lightning_arc_resource: Resource = load(_lightning_arc_scene)
	for i in range(_LIGHTNING_ARC_POOL_SIZE):
		_lightning_arc_pool.append(lightning_arc_resource.instantiate())
		add_child(_lightning_arc_pool[-1], true)
	
	# Authority-only functionality
	if is_multiplayer_authority():
		# Convert spawn event times from string to int
		for event: EnemySpawnEventData in spawn_events:
			var split: int = event.start_time.find(":")
			event.start_time_seconds = (
				int(event.start_time.substr(0, split)) * 60 + 
				int(event.start_time.substr(split + 1, len(event.start_time) - split))
			)
			split = event.end_time.find(":")
			if len(event.end_time) != 0:
				event.end_time_seconds  = (
					int(event.end_time.substr(0, split)) * 60 + 
					int(event.end_time.substr(split + 1, len(event.end_time) - split))
				)
			else:
				event.end_time_seconds = event.start_time_seconds
		
		# Sort the spawn events by decreasing start time.
		spawn_events.sort_custom(func(a: EnemySpawnEventData, b: EnemySpawnEventData):
			return a.start_time_seconds > b.start_time_seconds
		)
		
		# Play starting dialogue.
		if get_tree().paused:
			await GameState.unpaused
		hud_canvas_layer.start_dialogue([Constants.DialoguePlayCondition.START, _map_dialogue_condition])


## Only process on the server.
func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Process spawn events as they become active.
	while _current_spawn_event < len(spawn_events) and GameState.time <= spawn_events[_current_spawn_event].start_time_seconds:
		var spawn_start_time: float = 0.0
		
		for spawner: EnemySpawner in regular_enemy_spawners:
			spawner.spawn_repeating(spawn_events[_current_spawn_event], spawn_start_time)
			spawn_start_time += spawn_events[_current_spawn_event].spawn_interval_offset
		
		_current_spawn_event += 1
	
	if not _has_corrupted_enemy_spawned:
		if GameState.get_game_progress_as_fraction() >= corrupted_enemy_spawn_time_fraction:
			_spawn_corrupted_enemy()
	elif not _has_boss_spawned:
		if GameState.get_game_progress_as_fraction() >= 1.0:
			_spawn_boss.rpc()
			hud_canvas_layer.start_dialogue([Constants.DialoguePlayCondition.BOSS, _map_dialogue_condition])


## Add a new EnemySpawnEventData to all spawners on the map. 
func spawn_enemies(spawn_event: EnemySpawnEventData) -> void:
	var spawn_start_time: float = 0.0
	for spawner: EnemySpawner in regular_enemy_spawners:
		spawner.spawn_repeating(spawn_event, spawn_start_time)
		spawn_start_time += spawn_event.spawn_interval_offset


# Spawn the corrupted magical girl enemy.
func _spawn_corrupted_enemy() -> void:
	# Choose a character at random to spawn that wasn't picked by any of the players.
	# If all characters have been picked, then choose at random from all options.
	var valid_choices := corrupted_enemy_choices.duplicate()
	
	for key in GameState.players:
		var character_name: String = Constants.Character.keys()[GameState.players[key]["character"]].to_lower()
		if character_name in valid_choices:
			valid_choices.erase(character_name)
	if len(valid_choices) == 0:
		valid_choices = corrupted_enemy_choices.duplicate()
	var corrupted_enemy_scene: PackedScene = valid_choices.values().pick_random()
	
	_has_corrupted_enemy_spawned = true
	if corrupted_enemy_spawner != null and corrupted_enemy_scene != null:
		corrupted_enemy_spawner.spawn(corrupted_enemy_scene)


## Asynchronously spawn a bunch of EXP and Gold around a location when the 
## Corrupted Enemy is defeated. At most one of each is spawned per frame.
func spawn_corrupted_enemy_loot(loot_position: Vector2, exp_amount: int, gold_amount: int) -> void:
	var exp_spawned: int = 0
	var gold_spawned: int = 0
	
	while exp_spawned < exp_amount and gold_spawned < gold_amount:
		# Only try to spawn while the game is unpaused.
		if not get_tree().paused:
			# EXP
			if exp_spawned < exp_amount:
				var exp_orb: EXPOrb = exp_scene.instantiate()
				var spawn_position: Vector2 = loot_position + (Vector2.UP * randf_range(0.0, 200.0)).rotated(randf_range(0.0, TAU))
				exp_orb.global_position = spawn_position
				exp_orb.tree_entered.connect(
					func(): exp_orb.teleport.rpc(spawn_position)
					, CONNECT_DEFERRED
				)
				add_child(exp_orb, true)
				exp_spawned += 1
			
			# Gold
			if gold_spawned < gold_amount:
				var gold := gold_scene.instantiate()
				var spawn_position: Vector2 = loot_position + (Vector2.UP * randf_range(0.0, 200.0)).rotated(randf_range(0.0, TAU))
				gold.global_position = spawn_position
				gold.tree_entered.connect(
					func(): gold.teleport.rpc(spawn_position)
					, CONNECT_DEFERRED
				)
				add_child(gold, true)
				gold_spawned += 1
		
		await get_tree().process_frame


# Spawn the boss enemy. The game ends when it is defeated.
@rpc("authority", "call_local")
func _spawn_boss() -> void:
	var boss_to_spawn: PackedScene = boss_choices.pick_random()
	
	_has_boss_spawned = true
	GameState.pause_game()
	AudioManager.pause_music()
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.CONSTELLATION_SUMMON_RUMBLE)
	
	# Move camera and wait for it to be in position
	await _move_camera(corrupted_enemy_spawner.global_position)
	
	# Play boss summoning animation and wait for it to finish
	var cutscene_boss_animation = _spawn_boss_animation()
	# Wait for animation length
	await get_tree().create_timer(1.7).timeout
	AudioManager.create_audio(boss_sfx)
	
	# Make scene dark
	_grow_darkness() 
	
	# Pause to take in the boss
	await get_tree().create_timer(1).timeout
	
	#Reset camera, wait for it to be in position, then unpause the game
	await _reset_camera()
	await get_tree().create_timer(1.0).timeout
	
	GameState.pause_game(false)
	
	# Spawn in real boss and remove animation
	cutscene_boss_animation.queue_free()
	if (
			is_multiplayer_authority()
			and corrupted_enemy_spawner != null
			and boss_to_spawn != null
	):
		var boss: EnemyBoss = corrupted_enemy_spawner.spawn(boss_to_spawn)
		# Functionality after you defeat the boss.
		boss.died.connect(func(boss_node: Node2D): 
			_defeat_boss.rpc(boss_node.global_position)
			_update_map_complete_variable.rpc()
			hud_canvas_layer.start_dialogue([Constants.DialoguePlayCondition.WIN, _map_dialogue_condition])
		)
	AudioManager.play_boss_music()


## Show animation for when the boss is summoned
func _spawn_boss_animation() -> Node2D:
	var animated_boss = boss_animation.instantiate()
	animated_boss.global_position = corrupted_enemy_spawner.global_position
	add_child(animated_boss)
	return animated_boss


## Show animation for when the boss is defeated.
func _defeat_boss_animation(defeated_boss_position: Vector2) -> Node2D:
	var animated_boss = boss_animation.instantiate()
	var animation_player: AnimationPlayer = animated_boss.get_node("AnimationPlayer")
	
	animated_boss.global_position = defeated_boss_position
	add_child(animated_boss)
	animation_player.play("defeat")
	
	return animated_boss


## Play animation and finish the game when the boss is defeated.
@rpc("authority", "call_local", "reliable")
func _defeat_boss(boss_position: Vector2) -> void:
	AudioManager.pause_music()
	GameState.pause_game(true)
	_defeat_boss_animation(boss_position)
	await _move_camera(boss_position)
	
	_shrink_darkness()
	AudioManager.create_audio(boss_sfx)
	await get_tree().create_timer(3.0).timeout
	AudioManager.play_victory_music()
	
	GameState.finish_game(true)


## Darken the lighting when the boss spawns.
func _grow_darkness() -> void:
	if point_light != null:
		point_light.global_position = corrupted_enemy_spawner.global_position
		point_light.grow_darkness()
		# For some reason, there is 1 frame of the point light covering the full screen
		await get_tree().create_timer(0.01).timeout
		point_light.show()


## Turn lighting back to normal when boss is defeated.
@rpc("authority", "call_local")
func _shrink_darkness() -> void:
	# Make scene dark
	if point_light != null:
		point_light.global_position = corrupted_enemy_spawner.global_position
		point_light.show()
		point_light.shrink_darkness()


## Used to move the player's camera on a location
func _move_camera(to_pos:Vector2) -> Signal:
	if point_light != null:
		return point_light.move_camera(to_pos)
	
	# Return a timeout signal anyways so that whatever calls this doesn't get stuck.
	return get_tree().create_timer(1.0, false).timeout


## Used to reset the player's camera after using _move_camera()
func _reset_camera() -> Signal:
	if point_light != null:
		return point_light.reset_camera()
	
	# Return a timeout signal anyways so that whatever calls this doesn't get stuck.
	return get_tree().create_timer(1.0, false).timeout


## Set the variable indicating that this player has beaten this map to "true".
@rpc("authority", "call_local", "reliable")
func _update_map_complete_variable() -> void:
	GameState.set(map_win_save_variable_name, true)


#region ObjectPools

## Create a damage indicator VFX at a location
@rpc("authority", "call_local")
func create_damage_indicator(pos: Vector2, damage: float, is_crit: bool = false) -> void:
	_damage_indicator_pool[_damage_indicator_index].animate(pos, damage, is_crit)
	_damage_indicator_index += 1
	if _damage_indicator_index >= _DAMAGE_INDICATOR_POOL_SIZE:
		_damage_indicator_index = 0


## Create a BulletLightningArc object using an object pool, which is better than spawning new objects.
@rpc("authority", "call_local")
func create_lightning_arc(pos: Vector2, damage: float, is_crit: bool, is_owned_by_player: bool, owner_id: int,
			powerup_index: int, data: Array) -> void:
	_lightning_arc_pool[_lightning_arc_index].position = pos
	_lightning_arc_pool[_lightning_arc_index].set_damage(damage, is_crit)
	_lightning_arc_pool[_lightning_arc_index].setup_bullet(is_owned_by_player, data)
	if owner_id > 0 and powerup_index > -1:
		_lightning_arc_pool[_lightning_arc_index].setup_analytics(owner_id, powerup_index)
	
	_lightning_arc_index += 1
	if _lightning_arc_index >= _LIGHTNING_ARC_POOL_SIZE:
		_lightning_arc_index = 0

#endregion ObjectPools
