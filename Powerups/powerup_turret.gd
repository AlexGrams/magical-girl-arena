class_name PowerupTurret
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
## How long the turret is boosted for if this powerup is level 3 or higher.
var _level_3_boost_duration: float = 0.0
## Time remaining that this powerup is boosted by Marigold ultimate.
var _ultimate_boost_duration: float = 0.0


func set_ultimate_boost_duration(value: float) -> void:
	_ultimate_boost_duration = value


func _ready() -> void:
	super()
	_bullet_spawner = GameState.playground.bullet_spawner


func _process(delta: float) -> void:
	if not is_on:
		return
	
	if _ultimate_boost_duration > 0.0:
		_ultimate_boost_duration -= delta
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		# TODO: Place turret audio.
		#AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.MINES_DROPPED)
		
		# Each turret is moved to a random position in a circle around the player.
		var displacement: Vector2 = Vector2.UP.rotated(randf_range(0, 2 * PI)) * randf_range(0, _max_range)
		_bullet_spawner.request_spawn_bullet.rpc_id(
				1,
				[
					_bullet_scene, 
					global_position + displacement, 
					Vector2.ZERO, 
					_get_damage_from_curve(), 
					false,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[
						_turret_fire_interval, 
						_current_turret_lifetime, 
						max(_level_3_boost_duration, _ultimate_boost_duration),
						crit_chance,
						crit_multiplier
					]
				]
			)
		
		_shoot_timer = 0


func activate_powerup():
	super()
	
	if _deactivation_sources <= 0:
		is_on = true


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	super()
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if current_level >= 3:
		_level_3_boost_duration = 2.0
	if current_level >= 5 and is_signature:
		_current_turret_lifetime = 2.0 * _turret_lifetime


func boost() -> void:
	shoot_interval /= 2.0


func unboost() -> void:
	shoot_interval *= 2.0


func boost_fire_rate() -> void:
	_turret_fire_interval *= 0.75
