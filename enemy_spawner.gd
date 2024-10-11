extends Node2D

@export var rate:float
@onready var enemy_scene = preload("res://enemy.tscn")
var spawn_timer:float = 0
var is_on:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer > rate and is_on:
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position + Vector2(randf_range(-500, 500), randf_range(-10, 10))
		enemy.global_position = spawn_pos
		get_tree().root.add_child(enemy)
		spawn_timer = 0
