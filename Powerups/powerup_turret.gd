extends Powerup
## Creates a turret that shoots nearby targets.


## Time in seconds between creating bullets.
@export var shoot_interval = 5.0
## Farthest distance that a turret is placed from the player.
@export var _max_range: float = 100.0
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
## Time in seconds between turret shooting.
@export var _turret_fire_interval: float = 1.0
## Time in seconds that each turret lasts by default.
@export var _turret_lifetime: float = 10.0

@onready var _shoot_timer: float = shoot_interval
## Modified duration that each turret lasts for.
@onready var _current_turret_lifetime: float = _turret_lifetime

var _bullet_spawner: BulletSpawner = null
var _has_level_3_upgrade: bool = false


func _ready() -> void:
	_bullet_spawner = GameState.playground.bullet_spawner


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		# TODO: Place turret audio.
		#AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.MINES_DROPPED)
		
		var turret_lifetime: float = _turret_lifetime
		if current_level >= 5 && is_signature:
			turret_lifetime *= 2.0
		# Each turret is moved to a random position in a circle around the player.
		var displacement: Vector2 = Vector2.UP.rotated(randf_range(0, 2 * PI)) * randf_range(0, _max_range)
		_bullet_spawner.request_spawn_bullet.rpc_id(
				1,
				[
					_bullet_scene, 
					global_position + displacement, 
					Vector2.ZERO, 
					_get_damage_from_curve(), 
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[_turret_fire_interval, _current_turret_lifetime, _has_level_3_upgrade]
				]
			)
		
		_shoot_timer = 0


func activate_powerup():
	is_on = true


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if current_level >= 3:
		_has_level_3_upgrade = true
	if current_level >= 5 and is_signature:
		_current_turret_lifetime = 2.0 * _turret_lifetime
