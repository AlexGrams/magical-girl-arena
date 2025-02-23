class_name Playground
extends Node2D
## Script for controlling events that occur during gameplay.

## Time in seconds from the start of the game, expressed as a ratio between the elapsed game 
## time and the total game time, at which the corrupted magical girl enemy spawns. 0.0 is at the 
## start of the game, and 1.0 is at the end of the game timer.
@export var corrupted_enemy_spawn_time_fraction: float = 0.0
## Maps character name to the resource file of that character's corrupted Enemy object.
@export var corrupted_enemy_choices := {} 
## The EnemySpawner for spawning the corrupted magical girl.
@export var corrupted_enemy_spawner: EnemySpawner = null
## List of possible EnemyBoss scenes that can spawn at the end of the game.
@export var boss_choices: Array[PackedScene] = []
## List of events describing what enemies to spawn, when to spawn them, and how many to spawn.
@export var spawn_events: Array[EnemySpawnEventData] = []

var _has_corrupted_enemy_spawned := false
var _has_boss_spawned := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Only process on the server.
func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not _has_corrupted_enemy_spawned:
		if GameState.get_game_progress_as_fraction() >= corrupted_enemy_spawn_time_fraction:
			_spawn_corrupted_enemy()
	elif not _has_boss_spawned:
		if GameState.get_game_progress_as_fraction() >= 1.0:
			_spawn_boss()


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


# Spawn the boss enemy. The game ends when it is defeated.
func _spawn_boss() -> void:
	var boss_to_spawn: PackedScene = boss_choices.pick_random()
	
	_has_boss_spawned = true
	if corrupted_enemy_spawner != null and boss_to_spawn != null:
		corrupted_enemy_spawner.spawn(boss_to_spawn)
