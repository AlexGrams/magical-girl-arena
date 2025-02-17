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

var _has_corrupted_enemy_spawned := false


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
