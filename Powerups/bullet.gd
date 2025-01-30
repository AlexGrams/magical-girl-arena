class_name Bullet
extends Node2D
## A projectile that damages characters it touches.
## Replicated across clients.
## Default behavior is to move forward for some time


@export var speed: float = 5
@export var lifetime: float = 2
var direction: Vector2
var death_timer: float = 0


func set_damage(damage: float):
	$Area2D.damage = damage


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	global_position += direction * speed
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	if is_multiplayer_authority():
		queue_free()


# Set up other properties for this bullet
func setup_bullet(_data: Array) -> void:
	pass
