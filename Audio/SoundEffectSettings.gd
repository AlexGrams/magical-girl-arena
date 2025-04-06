extends Resource
class_name SoundEffectSettings

enum SOUND_EFFECT_TYPE{
	# Powerups
	BOOMERANG,
	LASER,
	ORBIT,
	REVOLVING,
	SCYTHE,
	SHOOTING,
	TRAIL,
	# Ultimates
	ON_GOTH_ULTIMATE,
	ON_SWEET_ULTIMATE,
	# Taking damage
	ON_ENEMY_DEATH,
	ON_ENEMY_HIT,
	ON_PLAYER_DEATH,
	ON_PLAYER_HIT,
	ON_BUSH_HIT,
	ON_BUSH_DESTROYED,
	# Pickup
	ON_EXP_PICKUP,
	ON_GOLD_PICKUP,
	ON_HEALTH_PICKUP,
	# Movement
	ON_PLAYER_MOVE,
	ON_ENEMY_MOVE,
	# UI
	UI_BUTTON_HOVER,
	UI_BUTTON_PRESS
}

@export_range(0, 20) var limit : int = 20
@export var type : SOUND_EFFECT_TYPE
@export var sound_effect : AudioStreamMP3
@export_range(-40, 20) var volume = 0
@export var pitch_scale = 1.0
@export var pitch_randomness = 0.0

var audio_count = 0

func update_audio_count(amount: int):
	audio_count = max(0, audio_count + amount)
	
func has_reached_limit() -> bool:
	return audio_count >= limit

func on_audio_finished():
	update_audio_count(-1)
