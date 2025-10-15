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

## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## True for the one frame for which the bullet's collider is active.
var _is_collision_active = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	
	sprite.scale = Vector2.ZERO
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	
	var audio_player = preload("res://Audio/Corvus_Raindrop_AudioPlayer.tscn").instantiate()
	# 0.605 is how long the "pop" part of the SFX lasts
	audio_player.global_position = global_position
	audio_player.pitch_scale = (audio_player.stream.get_length() / (lifetime + 0.605))
	get_tree().root.add_child(audio_player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	death_timer += delta
	
	if death_timer >= lifetime:
		# Turn the hitbox on for one frame, then delete it.
		if not _is_collision_active:
			_is_collision_active = true
			collider.collision_layer = _collision_layer
			
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
		sprite_child.scale = Vector2(1.0, 1.0) / sprite.scale


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (len(data) != 0
	):
		push_error("Malformed Bullet setup")
		return
	
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		push_error("bullet_boss_raindrop not implemented for players")
