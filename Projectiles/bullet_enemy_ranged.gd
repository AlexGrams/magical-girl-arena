extends Node2D

@export var speed: float = 5
@export var lifetime: float = 2
var direction: Vector2
var death_timer: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += direction * speed
	
	death_timer += delta
	if death_timer >= lifetime:
		queue_free()

func _on_area_2d_area_entered(_area: Area2D) -> void:
	queue_free()

func set_damage(damage:float):
	$Area2D.damage = damage
