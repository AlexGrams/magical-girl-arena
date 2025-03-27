class_name EnemySpawner
extends AreaSpawner


# All spawn events that are running on this spawner.
# 0: EnemySpawnEventData - information for this spawn event.
# 1: float - time until the next activation.
var _active_spawn_events: Array[Array] = []


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


# Function to spawn enemies repeatedly from this spawner.
func spawn_repeating(spawn_event: EnemySpawnEventData, start_time: float = 0.0) -> void:
	_active_spawn_events.append([spawn_event, start_time])
