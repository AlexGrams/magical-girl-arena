extends Bullet
## Pushes back hit enemies


## Magnitude of knockback in units/second.
@export var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.5


func _ready() -> void:
	rotation = direction.angle() + deg_to_rad(90)
	super()


func _process(delta: float) -> void:
	super(delta)


func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null and enemy is Enemy:
		enemy.set_knockback(direction * _knockback_speed, _knockback_duration)


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	sprite.self_modulate.a = GameState.other_players_bullet_opacity
