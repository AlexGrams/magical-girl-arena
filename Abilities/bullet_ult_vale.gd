extends Bullet
## A Bullet that waits some time before it does damage. Similar to other "Raindrop"-type bullets.


## Particles to spawn when damage activates.
@export var vfx_scene_path: String = ""

## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## True for the one frame for which the bullet's collider is active.
var _is_collision_active = false


func _ready() -> void:
	set_process(false)
	
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	$Sprite2D/AnimationPlayer.speed_scale = 1 / lifetime
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_GROW, true, lifetime)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	death_timer += delta
	
	if death_timer >= lifetime:
		# Turn the hitbox on for one frame, then delete it.
		if not _is_collision_active:
			_is_collision_active = true
			collider.collision_layer = _collision_layer
			
			# Play bubble SFX
			AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_POP)
			
			# Make particles
			var playground: Node2D = get_tree().root.get_node_or_null("Playground")
			if playground != null:
				var vfx: GPUParticles2D = load(vfx_scene_path).instantiate()
				vfx.global_position = global_position
				playground.add_child(vfx)
		elif is_multiplayer_authority():
			queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (len(data) != 2
		or typeof(data[0]) != TYPE_NODE_PATH	# Path to target
		or typeof(data[1]) != TYPE_FLOAT		# Lifetime
	):
		push_error("Malformed Bullet setup")
		return
	
	lifetime = data[1]
	
	if not is_owned_by_player:
		push_error("bullet_ult_vale not implemented for enemies.")
