extends Node2D

@export var rate: float
@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
var spawn_timer:float = 0
var is_on:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
