extends Bullet


## Particles to spawn when damage activates.
@export var _vfx_path: String = ""

var _max_scale: Vector2 = Vector2.ONE
## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## True for the one frame for which the bullet's collider is active.
var _is_collision_active = false


func _ready() -> void:
	_max_scale = scale
	scale = Vector2.ZERO
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_GROW, true, lifetime)


func _process(delta: float) -> void:
	death_timer += delta
	if death_timer < lifetime:
		# Grow and move
		global_position += direction * speed * delta
		scale = (death_timer / lifetime) * _max_scale


func _physics_process(_delta: float) -> void:
	if death_timer >= lifetime:
		# Bubble pops. Turn the hitbox on for one frame, then delete it.
		if not _is_collision_active:
			_is_collision_active = true
			collider.collision_layer = _collision_layer
			
			# Play bubble SFX
			AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_POP)
			
			# Make particles
			var playground: Node2D = get_tree().root.get_node_or_null("Playground")
			if playground != null:
				var vfx: GPUParticles2D = load(_vfx_path).instantiate()
				vfx.global_position = global_position
				playground.add_child(vfx)
		elif is_multiplayer_authority():
			queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 0
	):
		push_error("Malformed bullet setup data Array.")
		return
	
	_is_owned_by_player = is_owned_by_player
