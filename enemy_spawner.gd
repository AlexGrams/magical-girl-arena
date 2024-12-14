extends Node2D

# Time in seconds between enemy spawns
@export var rate: float
@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
var spawn_timer: float = 0
var is_on: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: Fix this check or something. 
	# Doing .to_string() doesn't work for getting the path
	if enemy_scene != null:
		load(enemy_scene.to_string())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer > rate and is_on and enemy_scene != null:
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position + Vector2(randf_range(-500, 500), randf_range(-10, 10))
		enemy.global_position = spawn_pos
		get_tree().root.add_child(enemy)
		spawn_timer = 0

func set_enemy_type(new_enemy: PackedScene) -> void:
	enemy_scene = new_enemy

# Set time in seconds between enemy spawns
func set_spawn_rate(new_rate: float) -> void:
	rate = new_rate
	
# Enable or disable this spawner
func set_on(new_is_on: bool) -> void:
	is_on = new_is_on
	
# Toggle this spawner
func toggle_on() -> void:
	is_on = !is_on
