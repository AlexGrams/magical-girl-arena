extends Node2D

@export var enemy_scene: PackedScene = preload("res://Enemies/enemy.tscn")
@export var enabled: bool = true
# Time in seconds until the next enemy spawn.
var spawn_timer: float = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enemy_scene != null:
		load(enemy_scene.resource_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Only the server controls spawning
	if (multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED 
		or not multiplayer.is_server()):
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0.0 and enabled and enemy_scene != null:
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position + Vector2(randf_range(-500, 500), randf_range(-10, 10))
		enemy.global_position = spawn_pos
		get_node("..").add_child(enemy, true)
		spawn_timer = GameState.get_spawn_interval()


func set_enemy_type(new_enemy: PackedScene) -> void:
	enemy_scene = new_enemy


# Enable or disable this spawner
func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled


# Toggle this spawner
func toggle_enabled() -> void:
	enabled = !enabled
