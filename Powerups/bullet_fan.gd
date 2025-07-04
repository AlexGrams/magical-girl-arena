extends Bullet
## Pushes back hit enemies


## Magnitude of knockback in units/second.
@export var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.5


func _ready() -> void:
	super()


func _process(delta: float) -> void:
	super(delta)


func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null and enemy is Enemy:
		enemy.set_knockback(direction * _knockback_speed, _knockback_duration)
