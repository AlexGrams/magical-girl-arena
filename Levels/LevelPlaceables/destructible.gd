class_name DestructibleNode2D
extends Node2D
## An object that can be damaged by players but is not an Enemy.


@export var max_health: float = 100.0

## Current health.
var _health: float = 0.0
## How much continuous damage this destructable takes each physics frame.
var _continuous_damage: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_health = max_health


func _physics_process(_delta: float) -> void:
	if _continuous_damage > 0:
		take_damage(_continuous_damage)


## Move LootBox to a location. Call using RPC for replication.
@rpc("authority", "call_local")
func teleport(pos: Vector2) -> void:
	global_position = pos


func _on_area_2d_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	if area is BulletHitbox:
		take_damage(area.damage)


## Destroy this object.
func _destroy() -> void:
	queue_free()


func take_damage(damage: float, _hitbox: BulletHitbox = null) -> void:
	if not is_multiplayer_authority():
		return
	
	if _health <= 0.0:
		return
	
	_health -= damage
	if _health <= 0.0:
		_destroy()


func add_continuous_damage(damage: float) -> void:
	_continuous_damage = max(_continuous_damage + damage, 0)
