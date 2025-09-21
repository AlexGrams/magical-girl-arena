@tool
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
	ON_LASER_HIT, # for unique laser hit sound
	ON_TRAIL_HIT, # for unique trail hit sound
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
	UI_BUTTON_PRESS,
	# Powerup
	RAINDROP_POP,
	RAINDROP_GROW,
	CUPID_ARROW,
	HEARTBEATBURST_EXPLOSION,
	HEARTBEATBURST_LAUNCH,
	MINES_DROPPED,
	MINES_SEEDS,
	MINES_EXPLODED,
	# Shop
	ITEM_PURCHASED,
	CONSTELLATION_SUMMON_RUMBLE,
	CORVUS_SUMMON,
	# More enemy hits
	ON_ENEMY_HIT_REVOLVING,
	ON_ENEMY_HIT_SCYTHE,
	ON_ENEMY_HIT_ORBIT,
	ON_ENEMY_HIT_MINES,
	# Default
	NONE
}

@export_range(0, 20) var limit : int = 20
@export var type : SOUND_EFFECT_TYPE :
	set(new_type):
		if new_type != type:
			type = new_type
			set_name(SOUND_EFFECT_TYPE.keys()[type])
			emit_changed()
@export var sound_effect : AudioStream
@export_range(-40, 20) var volume = 0
@export var pitch_scale = 1.0
@export var pitch_randomness = 0.0
## How much time in MILISECONDS must pass before this sound can be played again
@export var cooldown : int = 0
## Name of audio bus to be placed in
@export var bus: String
## Whether or not sfx plays during game pauses (like during upgrade screen)
@export var play_while_paused:bool = false

var audio_count:int = 0
var last_time_played:int = -1
	
func update_audio_count(amount: int):
	audio_count = max(0, audio_count + amount)
	last_time_played = Time.get_ticks_msec()

## Returns TRUE if sfx has NOT reached its limit AND is NOT on cooldown
func can_be_played() -> bool:
	return !has_reached_limit() and !is_on_cooldown()
	
func has_reached_limit() -> bool:
	return audio_count >= limit

## TRUE if it's on cooldown and SHOULD NOT be played. FALSE if it's not on cooldown and can be played.
func is_on_cooldown() -> bool:
	var current_time = Time.get_ticks_msec()
	return (current_time - last_time_played) < cooldown

func on_audio_finished():
	update_audio_count(-1)
