class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene = preload("res://Enemies/enemy.tscn")
@export var enabled: bool = true
## True if this spawner makes enemies periodically.
@export var automatic_spawning := true
# The rectangular shape for the area in which enemies will spawn in 
@export var spawn_area: CollisionShape2D = null

# Time in seconds until the next enemy spawn.
var spawn_timer: float = 0
# The bounds for spawning in global coordinates.
var _spawn_x_min: float = 0
var _spawn_x_max: float = 0
var _spawn_y_min: float = 0
var _spawn_y_max: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enemy_scene != null:
		load(enemy_scene.resource_path)
	
	var spawn_rect := spawn_area.get_shape().get_rect()
	_spawn_x_min = global_position.x + spawn_rect.position.x * global_scale.x
	_spawn_x_max = global_position.x + (spawn_rect.position.x + spawn_rect.size.x) * global_scale.x
	_spawn_y_min = global_position.y + spawn_rect.position.y * global_scale.y
	_spawn_y_max = global_position.y + (spawn_rect.position.y + spawn_rect.size.y) * global_scale.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Only the server controls spawning
	if (multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED 
		or not multiplayer.is_server()):
		return
	
	if automatic_spawning:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and enabled and enemy_scene != null:
			spawn()
			spawn_timer = GameState.get_spawn_interval()


func set_enemy_type(new_enemy: PackedScene) -> void:
	enemy_scene = new_enemy


# Enable or disable this spawner
func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled


# Toggle this spawner
func toggle_enabled() -> void:
	enabled = !enabled


# Make an enemy of this spawner's type within its designated spawn area. Spawning is
# done periodically by default, but this function can be called to spawn manually.
func spawn(scene_to_spawn: PackedScene = enemy_scene) -> void:
	var enemy = scene_to_spawn.instantiate()
	var spawn_pos = Vector2(
		randf_range(_spawn_x_min, _spawn_x_max), 
		randf_range(_spawn_y_min, _spawn_y_max)
	)
	enemy.global_position = spawn_pos
	get_node("..").add_child(enemy, true)
