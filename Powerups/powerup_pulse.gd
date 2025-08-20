class_name PowerupPulse
extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 3.0
## Path to the PowerupData resource file for this Powerup.
@export var _powerup_data_file_path: String = ""

var _fire_timer: float = 0.0
var _owner: PlayerCharacterBody2D = null
## Powerup owner's multiplayer ID.
var _id: int = 0


func _ready() -> void:
	powerup_name = load(_powerup_data_file_path).name
	_owner = get_parent()
	_id = multiplayer.get_unique_id()


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		# Apply StatusPulse to the other character
		var status_pulse: Status = _owner.get_status("Pulse")
		if status_pulse == null:
			status_pulse = StatusPulse.new()
			status_pulse.set_properties(
				_id, 
				_get_damage_from_curve(), 
				current_level >= 3,
				crit_chance,
				crit_multiplier
			)
			_owner.add_status(status_pulse)
		else:
			status_pulse.stack()
		
		# TODO: Play sound effect
		# AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CUPID_ARROW)
		_fire_timer -= _fire_interval


func activate_powerup():
	is_on = true
	_fire_timer = 1.0 - (GameState.time - int(GameState.time))


func deactivate_powerup():
	is_on = false
	_fire_timer = 0.0


func level_up():
	current_level += 1
