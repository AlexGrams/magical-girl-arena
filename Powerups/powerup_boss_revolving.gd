extends Powerup
## Revolving powerup but for bosses. Revolving lines are double-sided.

## Bullets are spaced evenly around in a circle
@export var _num_bullets_per_revolution := 12
@export var _damage: float = 25.0
## Time in seconds between activations
@export var _shoot_interval: float = 1.0
## Path to the scene for the powerup bullets
@export var _bullet_scene := ""

var _rotation_increment: float = 0.0
var _shoot_timer: float = 0.0
var _shoot_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	_rotation_increment = 2.0 * PI / _num_bullets_per_revolution
	if not is_multiplayer_authority():
		set_process(false)


func _process(delta: float) -> void:
	if is_on:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_shoot()
			_shoot_timer = _shoot_interval


func activate_powerup():
	is_on = true
	_shoot_timer = _shoot_interval
	# Initialize the shoot vector to a random rotation.
	_shoot_vector = Vector2.RIGHT.rotated(PI * 2.0 * randf())


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false


# Shoot around in a circle.
func _shoot() -> void:
	# TODO: Make a sound when we figure out what sound it should make.
	#AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_SWEET_ULTIMATE)
	
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, 
		[
			_bullet_scene, 
			get_parent().global_position, 
			_shoot_vector, 
			_damage, 
			false,
			false,
			-1,
			-1,
			[]
		]
	)
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, 
		[
			_bullet_scene, 
			get_parent().global_position, 
			_shoot_vector.rotated(PI), 
			_damage, 
			false,
			false,
			-1,
			-1,
			[]
		]
	)
	_shoot_vector = _shoot_vector.rotated(_rotation_increment)
