extends Powerup

## Time between creating puddles
@export var shoot_interval: float = 1.0
## Path to the Bullet-derived bullet scene.
@export var bullet_scene := ""
## Time in seconds between shooting signature powerup bullets.
@export var signature_interval: float = 4.0
## Path to the Bullet-derived signature bullet scene.
@export var signature_bullet_scene: String = ""

var _shoot_timer: float = 0
## How much damage the powerup does at its current level.
var _damage: float = 0.0
## Lifetime for bullet. Doubles at level 3
var _trail_lifetime: float = 2
var _signature_active: bool = false
var _signature_timer: float = 0.0
var _bullet_spawner: BulletSpawner = null

signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	_damage = _get_damage_from_curve()
	_bullet_spawner = GameState.playground.bullet_spawner


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		var crit: bool = randf() <= crit_chance
		var total_damage: float = _damage * (1.0 if not crit else crit_multiplier)
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.TRAIL)
		_bullet_spawner.request_spawn_bullet.rpc_id(
			1, 
			[
				bullet_scene, 
				global_position, 
				Vector2.ZERO, 
				total_damage,
				crit,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[
					_trail_lifetime,
					_area_size_boosted
				]
			]
		)
		_shoot_timer = 0
	
	# Signature
	if _signature_active:
		_signature_timer += delta
		if _signature_timer > signature_interval:
			var spawn_position: Vector2 = global_position + 300.0 * Vector2.RIGHT.rotated(randf() * 2.0 * PI)
			var crit: bool = randf() <= crit_chance
			var total_damage: float = _damage * (1.0 if not crit else crit_multiplier)
			AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.TRAIL)
			_bullet_spawner.request_spawn_bullet.rpc_id(
				1, 
				[
					signature_bullet_scene, 
					spawn_position, 
					Vector2.ZERO, 
					total_damage,
					crit,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[
						_trail_lifetime,
						_area_size_boosted
					]
				]
			)
			_signature_timer = 0.0


func activate_powerup():
	super()
	
	if _deactivation_sources <= 0:
		is_on = true
		picked_up_powerup.emit()


func deactivate_powerup():
	super()
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	_damage = _get_damage_from_curve()
	if current_level == 3:
		_trail_lifetime = _trail_lifetime * 2
	if current_level == 5 and is_signature:
		_signature_active = true
	powerup_level_up.emit(current_level, _damage)


func boost() -> void:
	shoot_interval *= 0.5
	signature_interval *= 0.5


func unboost() -> void:
	shoot_interval *= 2.0
	signature_interval *= 2.0


func boost_area_size() -> void:
	super()
