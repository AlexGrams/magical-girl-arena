extends Bullet


## Time that the warning for the attacks appears before the damage volume becomes active.
@export var _tell_time: float = 2.0
## Time that this bullet remains active to damage players.
@export var _damage_time: float = 0.5
@export var _static_body: StaticBody2D = null

var _tell_timer: float = 0.0
var _damage_timer: float = 0.0
var _static_body_collision_layer: int = 0


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	if _tell_timer > 0.0:
		# Stage 1: Warn that the attack is coming.
		_tell_timer -= delta
		if _tell_timer <= 0.0:
			_modify_collider_to_harm_players()
			_damage_timer = _damage_time
	elif _damage_timer > 0.0:
		# Stage 2: Bullet can damage players.
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			collider.collision_layer = 0
			collider.collision_mask = 0
			_static_body.collision_layer = _static_body_collision_layer
			sprite.self_modulate = Color.WHITE


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (len(data) != 0
	):
		push_error("Malformed Bullet setup")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	if not is_owned_by_player:
		rotation = direction.angle()
		_tell_timer = _tell_time
		_static_body_collision_layer = _static_body.collision_layer
		_static_body.collision_layer = 0
