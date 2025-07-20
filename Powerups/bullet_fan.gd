extends Bullet
## Pushes back hit enemies


## Magnitude of knockback in units/second.
var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.5
## Width that the bullet should scale to (including sprite)
@export var bullet_width: float = 1

func _ready() -> void:
	rotation = direction.angle() + deg_to_rad(90)
	var tween = create_tween()
	var final_scale = Vector2(bullet_width, scale.y)
	tween.tween_property(self, "scale", final_scale, 0.25)
	super()


func _process(delta: float) -> void:
	super(delta)


func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null and enemy is Enemy:
		enemy.set_knockback(direction * _knockback_speed, _knockback_duration)

## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or typeof(data[0]) != TYPE_FLOAT	# Bullet width
		or typeof(data[1]) != TYPE_FLOAT	# Knockback speed
	):
		push_error("Malformed data array")
		return
		
	bullet_width = data[0]
	_knockback_speed = data[1]

## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	sprite.self_modulate.a = GameState.other_players_bullet_opacity
