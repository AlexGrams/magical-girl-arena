extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 3.0
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
## Path to the PowerupData resource file for this Powerup.
@export var _powerup_data_file_path: String = ""
## How long between double pulses (level 3+)
@export var _double_pulse_interval: float = 0.1

var _fire_timer: float = 0.0
var _owner: Node = null
var _double_pulse_started: bool = false


func _ready() -> void:
	powerup_name = load(_powerup_data_file_path).name
	_owner = get_parent()


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		print("HELLO")
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, 
			[
				_bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[_owner.get_path()]
			]
		)
		if current_level >= 3 and !_double_pulse_started:
			# Bool needed, otherwise spawns multiple pulses due to the way
			# _process works with timers
			_double_pulse_started = true
			await get_tree().create_timer(_double_pulse_interval).timeout
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, 
			[
				_bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[_owner.get_path()]
			]
			)
			_double_pulse_started = false
		
		# TODO: Play sound effect
		# AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CUPID_ARROW)
		_fire_timer = 0.0


func activate_powerup():
	is_on = true


func deactivate_powerup():
	is_on = false
	_fire_timer = 0.0


func level_up():
	current_level += 1
