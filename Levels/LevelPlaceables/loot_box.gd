class_name LootBox
extends Node2D
## A neutral destructable object in the world. When the player breaks it, 
## has a chance of spawning items such as gold or health for the player.
## Enemies cannot interact with a LootBox.

@export var max_health: float = 100.0

var _health: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_health = max_health


func _on_area_2d_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	if area is BulletHitbox:
		_health -= area.damage
		if _health <= 0.0:
			_destroy()


## Break this object and create a pickup. Only call on server.
func _destroy() -> void:
	queue_free()
