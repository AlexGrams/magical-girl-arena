class_name BulletBossTerrain
extends Bullet

## Y values for each dust cloud spawned. Manually put in because I'm lazy.
const Y_VALUES:Array[float] = [-150, -75, 0, 75, 150]

## Time that the warning for the attacks appears before the damage volume becomes active.
@export var _tell_time: float = 2.0
## Time that this bullet remains active to damage players.
@export var _damage_time: float = 0.5
@export var _static_body: StaticBody2D = null
## Sprite for rumbling warning
@export var _rumbling_sprite: Sprite2D
## Sprite for the actual terrain that damages and collides with players
@export var _terrain_sprite: Sprite2D
## GPUParticles2D for Dust cloud VFX
@export var _dust_cloud_particles: Resource

var _tell_timer: float = 0.0
var _damage_timer: float = 0.0
var _static_body_collision_layer: int = 0
# Whether or not the terrain has already appeared for the first time.
# Prevents dust cloud VFX from happening over and over
var _terrain_has_appeared: bool = false


func _ready() -> void:
	# Show rumbling cracks
	_rumbling_sprite.show()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(_rumbling_sprite, "scale", Vector2(_rumbling_sprite.scale.y, _rumbling_sprite.scale.y), 0.1)
	
	add_to_group("bullet_boss_terrain")


func _process(delta: float) -> void:
	if _tell_timer > 0.0:
		# Stage 1: Warn that the attack is coming.
		_tell_timer -= delta
		if _tell_timer <= 0.0:
			_modify_collider_to_harm_players()
			_damage_timer = _damage_time
	elif _damage_timer > 0.0:
		# Stage 2: Bullet can damage players.
		if !_terrain_has_appeared:
			show_terrain()
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
		if rotation < 0:
			rotation += PI
		_tell_timer = _tell_time
		_static_body_collision_layer = _static_body.collision_layer
		_static_body.collision_layer = 0

func show_terrain():
	_terrain_has_appeared = true
	_rumbling_sprite.hide()
	_terrain_sprite.show()
	
	# Terrain pops up
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(_terrain_sprite, "scale", Vector2(_terrain_sprite.scale.x, _terrain_sprite.scale.x), 0.1)
	
	# Dust clouds appear
	for y_value in Y_VALUES:
		var dust_cloud:GPUParticles2D = _dust_cloud_particles.instantiate()
		dust_cloud.position = Vector2(0, y_value)
		add_child(dust_cloud)

## Remove this object. Only call on server.
func destroy() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(_terrain_sprite, "scale", Vector2(_terrain_sprite.scale.x, 0), 0.1)
	tween.tween_callback(queue_free)
