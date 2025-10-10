extends Bullet


## Explosion VFX to spawn when damage activates.
@export var _vfx_uid: String = ""

## Saved bullet collision layer for when we reactivate the collision.
var _collision_layer: int = 0
var _explosion_time: float = lifetime
var _has_exploded:bool = false
var _is_level_3:bool = false


func _ready() -> void:
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	
	rotation = direction.angle() + deg_to_rad(90)


func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	# Explode either when time runs out or it collides with sometime. When it explodes, its collider 
	# is enabled for one physics frame before deleting the bullet.
	death_timer += delta
	
	if (
		collider.collision_layer != 0 and 
		is_multiplayer_authority() and 
		death_timer >= _explosion_time + 2.0 / 60.0
	):
		# Disgusting hack. For some reason, we need to wait two physics frames before
		# enemies detect that the grenade collision has changed. It doesn't work this 
		# way for the Boss Raindrop for some reason.
		queue_free()
	elif death_timer >= lifetime and !_has_exploded:
		_explode()
	else:
		global_position += direction * speed * delta


func _on_area_2d_area_entered(_area: Area2D) -> void:
	# Explode here. Trust that there is no networking stuff that causes this to become desyncd.
	_explode()


## Deal damage in an area around where the bullet is currently.
func _explode() -> void:
	_has_exploded = true
	_explosion_time = death_timer
	
	# Spawn explosion VFX
	var playground: Node2D = get_tree().root.get_node_or_null("Playground")
	if playground != null:
		var vfx: GPUParticles2D = load(_vfx_uid).instantiate()
		vfx.global_position = global_position
		if _is_level_3:
			vfx.scale = Vector2(2, 2)
		playground.add_child(vfx)
	sprite.hide()
	
	# Play SFX
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.HEARTBEATBURST_EXPLOSION)
	
	if is_multiplayer_authority():
		collider.collision_layer = _collision_layer

## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	# Increase explosion size at level 3
	_is_level_3 = data[2]
	if _is_level_3:
		var collision_shape = collider.get_child(0)
		collision_shape.shape.radius = collision_shape.shape.radius * 2
	
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.HEARTBEATBURST_LAUNCH)
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		push_error("bullet_grenade not implemented for enemies.")
		_is_owned_by_player = false
		_health = max_health
		_modify_collider_to_harm_players()
