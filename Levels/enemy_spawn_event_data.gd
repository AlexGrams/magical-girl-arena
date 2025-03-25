class_name EnemySpawnEventData
extends Resource
## Describes how enemies spawn as the game progresses.

## The beginning time of this event. Acceptable formats are [param mm:ss], [param m:ss], [param mm:s], [param m:s], and [param mm].
@export var start_time: String = ""
## The ending time of this event. If blank, then the event is instantaneous and doesn't repeat.
@export var end_time: String = ""
## The Enemy scene to spawn for this event. Enemies will be created from EnemySpawners.
@export var enemy: PackedScene = null
## The time in seconds between repeating spawns for this event. If the event is not instant, then this
## value should be greater than 0.
@export var spawn_interval: float = 1.0
## The time in seconds between each individual spawner creating enemies. If this is 0, then the enemies
## are created all at once. Otherwise, enemies will spawn in a "rotating" fashion from each spawner.
@export var spawn_interval_offset: float = 0.0
## The inclusive minimum number of enemies to spawn at each spawnere each time this event repeats.
## The number of enemies created is chosen uniformily at random from this range.
@export var min_spawn_count: int = 1
## The inclusive maximum number of enemies to spawn at each spawner each time this event repeats. If this
## is less than [param min_spawn_count], then this will be treated as equal to [param min_spawn_count].
@export var max_spawn_count: int = 0

## start_time converted from string to seconds. Set manually after game begins.
var start_time_seconds: int = 0
## end_time converted from string to seconds. Set manually after game begins.
var end_time_seconds: int = 0
