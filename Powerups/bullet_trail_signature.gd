extends BulletContinuous
## Heals the first ally that touches it, after which it becomes a regular trail bullet.


@export var _heal_amount: float = 5.0

var _heal_active: bool = true


func _on_area_2d_entered(area: Area2D) -> void:
	super(area)
	
	var other: Node2D = area.get_parent()
	if (
			_heal_active 
			and other is PlayerCharacterBody2D 
			and other.health < other.health_max
	):
		if other == GameState.get_local_player():
			other.take_damage(-_heal_amount)
			_destroy.rpc_id(1)
		_heal_active = false


## Only call on server.
@rpc("any_peer", "call_local")
func _destroy() -> void:
	queue_free()
