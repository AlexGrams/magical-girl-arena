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
	if not is_multiplayer_authority():
		return
	
	global_position += direction * speed
	
	death_timer += delta
	if death_timer >= lifetime:
		queue_free()


# Try to free this bullet remotely. Call from any client when their own character touches 
# this bullet.
@rpc("any_peer", "call_local")
func request_delete() -> void:
	queue_free()


func set_damage(damage:float):
	$Area2D.damage = damage
