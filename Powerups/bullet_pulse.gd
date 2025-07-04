extends Bullet


## Magnitude of knockback in units/second.
@export var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.25


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	scale += Vector2(delta * speed, delta * speed)
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null and enemy is Enemy:
		enemy.set_knockback((enemy.global_position - global_position).normalized() * _knockback_speed, _knockback_duration)
