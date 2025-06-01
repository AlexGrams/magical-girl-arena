extends Bullet


## Explosion VFX to spawn when damage activates.
@export var _vfx_uid: String = ""

## Saved bullet collision layer for when we reactivate the collision.
var _collision_layer: int = 0
var _explosion_time: float = lifetime
var _has_exploded:bool = false


func _ready() -> void:
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.HEARTBEATBURST_LAUNCH)
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


func _on_area_2d_area_entered(area: Area2D) -> void:
	if _is_owned_by_player:
		# Explode here. Trust that there is no networking stuff that causes this to become desyncd.
		_explode()
	elif is_multiplayer_authority():
		# Enemy's bullets should deal damage if they hit a player's bullet.
		# NOTE: Enemy bullets are deleted when the character that they hit calls an RPC to delete them.
		if area is BulletHitbox:
			take_damage(area.damage)


## Deal damage in an area around where the bullet is currently.
func _explode() -> void:
	_has_exploded = true
	_explosion_time = death_timer
	
	# Spawn explosion VFX
	var playground: Node2D = get_tree().root.get_node_or_null("Playground")
	if playground != null:
		var vfx: GPUParticles2D = load(_vfx_uid).instantiate()
		vfx.global_position = global_position
		playground.add_child(vfx)
	sprite.hide()
	
	# Play SFX
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.HEARTBEATBURST_EXPLOSION)
	
	if is_multiplayer_authority():
		collider.collision_layer = _collision_layer
