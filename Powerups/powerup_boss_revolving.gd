extends Powerup
# Shoots a bunch of projectiles out in a circle


## Bullets are spaced evenly around in a circle
@export var _num_bullets := 12
@export var _damage: float = 25.0
## Time in seconds between activations
@export var _shoot_interval: float = 1.0
## UID of the scene for the powerup bullets
@export var _bullet_scene_uid := ""

var _shoot_timer: float = 0.0


func _ready() -> void:
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
	
	# Shoot bullets all around
	var rotation_increment: float = 2 * PI / _num_bullets
	var random_starting_point = Vector2(randf(), randf()).normalized()
	for i in range(_num_bullets):
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [_bullet_scene_uid, 
			get_parent().global_position, 
			random_starting_point.rotated(rotation_increment * i), 
			_damage, 
			false,
			false,
			-1,
			-1,
			[]
		])
