extends Node2D

var player:Node2D
var speed:float = 100
@onready var exp_scene = preload("res://exp_orb.tscn")

func _ready() -> void:
	player = get_tree().root.get_node("Playground/CharacterBody2D")

func _process(delta: float) -> void:
	if player != null:
		global_position = global_position.move_toward(player.global_position, delta*speed)
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	var exp_orb = exp_scene.instantiate()
	exp_orb.global_position = global_position
	get_tree().root.call_deferred("add_child", exp_orb)
	queue_free()
