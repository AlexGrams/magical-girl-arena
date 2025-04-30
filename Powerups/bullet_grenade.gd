extends Bullet


## Explosion VFX to spawn when damage activates.
@export var _vfx_uid: String = ""

## Saved bullet collision layer for when we reactivate the collision.
var _collision_layer: int


func _ready() -> void:
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.REVOLVING)
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0


func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	# Explode either when time runs out or it collides with sometime. When it explodes, its collider 
	# is enabled for one physics frame before deleting the bullet.
	death_timer += delta
	if collider.collision_layer != 0:
		print("Free")
		queue_free()
	elif death_timer >= lifetime and sprite.visible:
		print("Ran out of time")
		_explode()


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
	# Spawn explosion VFX
	var playground: Node2D = get_tree().root.get_node_or_null("Playground")
	if playground != null:
		var vfx: GPUParticles2D = load(_vfx_uid).instantiate()
		vfx.global_position = global_position
		playground.add_child(vfx)
	sprite.hide()
	
	if is_multiplayer_authority():
		print("Collision is on")
		collider.collision_layer = _collision_layer
