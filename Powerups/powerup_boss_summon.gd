extends Powerup
## Boss powerup to spawn some enemies around the map.


## Enemy scene to spawn.
@export var _enemy_scene: String = ""
## Minimum number of enemies spawned at each spawner per wave.
@export var _min_spawn_count: int = 10
## Maximum number of enemies spawned at each spawner per wave.
@export var _max_spawn_count: int = 10
## Time in seconds between repeated spawns.
@export var _spawn_interval: float = 10.0
## How long this summon attack lasts for.
@export var _duration: float = 5.0

var _spawn_event_data: EnemySpawnEventData = EnemySpawnEventData.new()


func _ready() -> void:
	set_process(false)
	
	if multiplayer.is_server():
		_spawn_event_data.enemy = load(_enemy_scene)
		_spawn_event_data.min_spawn_count = _min_spawn_count
		_spawn_event_data.max_spawn_count = _max_spawn_count
		_spawn_event_data.spawn_interval = _spawn_interval


func _process(_delta: float) -> void:
	pass


func activate_powerup():
	is_on = true
	
	# Activate the spawn event
	var _new_spawn_event: EnemySpawnEventData = _spawn_event_data.duplicate()
	_new_spawn_event.start_time_seconds = GameState.time
	_new_spawn_event.end_time_seconds = GameState.time - _duration
	GameState.playground.spawn_enemies(_new_spawn_event)


## Only set _is_owned_by_player so that we don't spawn enemies immediately when the boss spawns in.
func activate_powerup_for_enemy():
	_is_owned_by_player = false


func deactivate_powerup():
	is_on = false
