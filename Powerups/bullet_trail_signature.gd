extends BulletContinuous
## Heals the first ally that touches it, after which it becomes a regular trail bullet.


@export var _heal_amount: float = 5.0
@export var _flower_sprites: Array[Sprite2D] = []

var _heal_active: bool = true


func _on_area_2d_entered(area: Area2D) -> void:
	super(area)
	
	var other: Node2D = area.get_parent()
	if other is PlayerCharacterBody2D and other.health < other.health_max:
		if other == GameState.get_local_player():
			other.take_damage(-_heal_amount)
		_heal_active = false
		for flower: Sprite2D in _flower_sprites:
			flower.self_modulate = Color.WHITE
