class_name BulletBossRaindrop
extends Bullet
## A Bullet that waits some time before it does damage. A visual indicator shows where the bullet
## will damage and indicates how long until damage is applied.


## Particles to spawn when damage activates.
@export var vfx_uid: String = ""

## How big the shadow of this attack is at its maximum value.
var _max_shadow_scale: Vector2 = Vector2.ONE
## Which Enemy this bullet is targeting if it was spawned by a player's powerup.
var _target: Node2D = null
## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## True for the one frame for which the bullet's collider is active.
var _is_collision_active = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_max_shadow_scale = sprite.scale
	sprite.scale = Vector2.ZERO
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_GROW, true, lifetime)


func _process(_delta: float) -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	death_timer += delta
	
	if _is_owned_by_player and _target != null:
		global_position = _target.global_position
	
	if death_timer >= lifetime:
		# Turn the hitbox on for one frame, then delete it.
		if not _is_collision_active:
			_is_collision_active = true
			collider.collision_layer = _collision_layer
			
			# Play SFX
			AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_POP)
			# Make particles
			var playground: Node2D = get_tree().root.get_node_or_null("Playground")
			if playground != null:
				var vfx: GPUParticles2D = load(vfx_uid).instantiate()
				vfx.global_position = global_position
				playground.add_child(vfx)
		elif is_multiplayer_authority():
			queue_free()
	else:
		sprite.scale = (death_timer / lifetime) * _max_shadow_scale


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if not is_owned_by_player:
		# Make the bullet hurt players and indestructible.
		_is_owned_by_player = false
		if sprite != null:
			sprite.self_modulate = Color.RED
	else:
		# Owned by player and was spawned by powerup_raindrop
		
		if (len(data) != 1 
			or typeof(data[0]) != TYPE_NODE_PATH	# Path to target
		):
			push_error("Malformed Bullet setup")
			return
		
		_target = get_tree().root.get_node_or_null(data[0])
