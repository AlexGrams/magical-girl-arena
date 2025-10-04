class_name PowerupPulse
extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 3.0

var _fire_timer: float = 0.0
var _owner: PlayerCharacterBody2D = null
## Powerup owner's multiplayer ID.
var _id: int = 0
var _pulse_counts: int = 0


func _ready() -> void:
	super()
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
				_powerup_index,
				_get_damage_from_curve(), 
				current_level >= 3,
				crit_chance,
				crit_multiplier,
				_area_size_boosted
			)
			_owner.add_status(status_pulse)
		elif current_level >= 3:
			status_pulse.stack()
		
		# TODO: Play sound effect
		# AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CUPID_ARROW)
		_fire_timer -= _fire_interval


func activate_powerup():
	super()
	
	if _deactivation_sources > 0:
		return
	
	is_on = true
	_fire_timer = 1.0 - (GameState.time - int(GameState.time))


func deactivate_powerup():
	super()
	is_on = false
	_fire_timer = 0.0


func level_up():
	current_level += 1


## Add a count of how many pulses were created this frame which originate from this Powerup owner.
## After waiting to account for network delay, play a different sound depending on how many pulses 
## were created that were caused by this Powerup. 
func add_pulse_this_beat() -> void:
	_pulse_counts += 1
	if _pulse_counts == 1:
		await get_tree().create_timer(0.1, false).timeout
		
		var pulse_sfx := SoundEffectSettings.SOUND_EFFECT_TYPE.NONE
		match _pulse_counts:
			1:
				pulse_sfx = SoundEffectSettings.SOUND_EFFECT_TYPE.PULSE_CHORD1 
			2:
				pulse_sfx = SoundEffectSettings.SOUND_EFFECT_TYPE.PULSE_CHORD2
			3:
				pulse_sfx = SoundEffectSettings.SOUND_EFFECT_TYPE.PULSE_CHORD3 
			4:
				pulse_sfx = SoundEffectSettings.SOUND_EFFECT_TYPE.PULSE_CHORD4 
		AudioManager.create_audio_at_location(global_position, pulse_sfx)
		_pulse_counts = 0
