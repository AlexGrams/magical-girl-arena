class_name EnemySpawner
extends Node2D

## Enemy that is spawned when we want to make a melee enemy.
@export var enemy_melee_scene: PackedScene
## Enemy that is spawned when we want to make a ranged enemy.
@export var enemy_ranged_scene: PackedScene
## True when this spawner is able to make Enemies automatically.
@export var enabled: bool = true
## True if this spawner makes enemies periodically.
@export var automatic_spawning := true
## The rectangular shape for the area in which enemies will spawn in 
@export var spawn_area: CollisionShape2D = null

# Time in seconds until the next melee enemy spawn.
var spawn_timer_melee: float = 0.0
# Time in seconds until the next ranged enemy spawn.
var spawn_timer_ranged: float = 0.0

# The bounds for spawning in global coordinates.
var _spawn_x_min: float = 0
var _spawn_x_max: float = 0
var _spawn_y_min: float = 0
var _spawn_y_max: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enemy_melee_scene != null:
		load(enemy_melee_scene.resource_path)
	if enemy_ranged_scene != null:
		load(enemy_ranged_scene.resource_path)
	
	var spawn_rect := spawn_area.get_shape().get_rect()
	_spawn_x_min = global_position.x + spawn_rect.position.x * global_scale.x
	_spawn_x_max = global_position.x + (spawn_rect.position.x + spawn_rect.size.x) * global_scale.x
	_spawn_y_min = global_position.y + spawn_rect.position.y * global_scale.y
	_spawn_y_max = global_position.y + (spawn_rect.position.y + spawn_rect.size.y) * global_scale.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Only the server controls spawning
	if (not multiplayer.is_server()
		or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED):
		return
	
	if automatic_spawning and enabled:
		spawn_timer_melee -= delta
		spawn_timer_ranged -= delta
		
		if spawn_timer_melee <= 0.0 and enemy_melee_scene != null:
			spawn(enemy_melee_scene)
			spawn_timer_melee = GameState.get_spawn_interval()
		if spawn_timer_ranged <= 0.0 and enemy_ranged_scene != null:
			spawn(enemy_ranged_scene)
			spawn_timer_melee = GameState.get_spawn_interval()


func set_enemy_type(new_enemy: PackedScene) -> void:
	push_error("DEPRECATED: May want to change how setting spawner types works.")
	#enemy_scene_ = new_enemy


# Enable or disable this spawner
func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled


# Toggle this spawner
func toggle_enabled() -> void:
	enabled = !enabled


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
