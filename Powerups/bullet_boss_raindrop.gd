class_name BulletBossRaindrop
extends Bullet
## A Bullet that waits some time before it does damage. A visual indicator shows where the bullet
## will damage and indicates how long until damage is applied.


## Particles to spawn when damage activates.
@export var vfx_uid: String = ""
## Child of initial Sprite2D. Used to scale for mask.
@export var sprite_child: Sprite2D
## How big the shadow of this attack is at its maximum value.
@export var _max_shadow_scale: Vector2 = Vector2.ONE
## Kinda dumb way to do this, but leaving it for now sorry.
@export var _is_vale_ultimate: bool = false
## Which Enemy this bullet is targeting if it was spawned by a player's powerup.
var _target: Node2D = null
## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## True for the one frame for which the bullet's collider is active.
var _is_collision_active = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _is_vale_ultimate:
		$Sprite2D/AnimationPlayer.speed_scale = 1 / lifetime
	else:
		sprite.scale = Vector2.ZERO
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	if _is_owned_by_player:
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_GROW, true, lifetime)
	else:
		var audio_player = preload("res://Audio/Corvus_Raindrop_AudioPlayer.tscn").instantiate()
		# 0.605 is how long the "pop" part of the SFX lasts
		audio_player.global_position = global_position
		audio_player.pitch_scale = (audio_player.stream.get_length() / (lifetime + 0.605))
		get_tree().root.add_child(audio_player)

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
			
			# Play bubble SFX
			if _is_owned_by_player:
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
		if not _is_vale_ultimate:
			sprite.scale = (death_timer / lifetime) * _max_shadow_scale
		if not _is_owned_by_player:
			sprite_child.scale = Vector2(1.0, 1.0) / sprite.scale


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if not is_owned_by_player:
		# Make the bullet hurt players and indestructible.
		_is_owned_by_player = false
	else:
		# Owned by player and was spawned by powerup_raindrop
		if (len(data) != 2
			or typeof(data[0]) != TYPE_NODE_PATH	# Path to target
			or typeof(data[1]) != TYPE_FLOAT		# Lifetime
			
		):
			push_error("Malformed Bullet setup")
			return
		
		_target = get_tree().root.get_node_or_null(data[0])
		lifetime = data[1]
