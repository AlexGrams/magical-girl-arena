class_name EnemySpawner
extends Node2D

## True when this spawner is able to make Enemies automatically.
@export var enabled: bool = true
## The rectangular shape for the area in which enemies will spawn in 
@export var spawn_area: CollisionShape2D = null

# The bounds for spawning in global coordinates.
var _spawn_x_min: float = 0
var _spawn_x_max: float = 0
var _spawn_y_min: float = 0
var _spawn_y_max: float = 0

# All spawn events that are running on this spawner.
# 0: EnemySpawnEventData - information for this spawn event.
# 1: float - time until the next activation.
var _active_spawn_events: Array[Array] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawn_rect := spawn_area.get_shape().get_rect()
	_spawn_x_min = global_position.x + spawn_rect.position.x * global_scale.x
	_spawn_x_max = global_position.x + (spawn_rect.position.x + spawn_rect.size.x) * global_scale.x
	_spawn_y_min = global_position.y + spawn_rect.position.y * global_scale.y
	_spawn_y_max = global_position.y + (spawn_rect.position.y + spawn_rect.size.y) * global_scale.y


# Enable or disable this spawner
func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled


# Toggle this spawner
func toggle_enabled() -> void:
	enabled = !enabled


func _process(delta: float) -> void:
	var i: int = 0
	
	while i < len(_active_spawn_events):
		var spawn_event: Array = _active_spawn_events[i]
		
		if spawn_event[1] <= 0.0:
			var enemies_to_spawn: int = spawn_event[0].min_spawn_count
			if spawn_event[0].max_spawn_count > spawn_event[0].min_spawn_count:
				enemies_to_spawn = randi_range(spawn_event[0].min_spawn_count, spawn_event[0].max_spawn_count)
			
			for j in range(enemies_to_spawn):
				spawn(spawn_event[0].enemy)
			
			# If this event is done repeating, then remove it
			if GameState.time - spawn_event[0].spawn_interval < spawn_event[0].end_time_seconds:
				_active_spawn_events.remove_at(i)
				continue
			else:
				_active_spawn_events[i][1] = spawn_event[0].spawn_interval
			
		spawn_event[1] -= delta
		i += 1
		


# Make an enemy of this spawner's type within its designated spawn area. Spawning is
# done periodically by default, but this function can be called to spawn manually.
func spawn(scene_to_spawn: PackedScene) -> void:
	var enemy = scene_to_spawn.instantiate()
	var spawn_pos = Vector2(
		randf_range(_spawn_x_min, _spawn_x_max), 
		randf_range(_spawn_y_min, _spawn_y_max)
	)
	enemy.global_position = spawn_pos
	get_node("..").add_child(enemy, true)


# Asynchronous function to spawn enemies repeatedly from this spawner.
func spawn_repeating(spawn_event: EnemySpawnEventData, start_time: float = 0.0) -> void:
	_active_spawn_events.append([spawn_event, start_time])
