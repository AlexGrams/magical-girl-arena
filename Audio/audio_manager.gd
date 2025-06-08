extends Node2D

# AudioManager is used for repetitive sound effects, such as picking up experience or damaging enemies
# Script created based on this video: https://www.youtube.com/watch?v=Egf2jgET3nQ

@export var sound_effect_settings : Array[SoundEffectSettings]
var sound_effect_dict : Dictionary

## Value by which to scale the volume of sounds played in the game.
var _volume_multiplier: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for sfx in sound_effect_settings:
		sound_effect_dict[sfx.type] = sfx


func set_volume_multiplier(value: float) -> void:
	_volume_multiplier = value


## Plays a sound. RPC calls to this should be used sparingly, as there are often ways to 
## replicate sounds without having to do a separate RPC just for the audio.
## For example, if a sound is played when the player shoots, the bullet's _ready function should
## create the sound instead of the shooting player calling this function via RPC.
@rpc("any_peer", "call_local")
func create_audio_at_location(location, sfx_type: SoundEffectSettings.SOUND_EFFECT_TYPE, change_length:bool = false, desired_length:float = -1):
	if sfx_type in sound_effect_dict:
		var sfx:SoundEffectSettings = sound_effect_dict[sfx_type]
		if !sfx.has_reached_limit():
			sfx.update_audio_count(1)
			var new_2D_audio = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			
			new_2D_audio.position = location
			new_2D_audio.stream = sfx.sound_effect
			new_2D_audio.volume_db = linear_to_db(db_to_linear(sfx.volume) * _volume_multiplier)
			if change_length:
				new_2D_audio.pitch_scale = (new_2D_audio.stream.get_length() / desired_length)
			else:
				new_2D_audio.pitch_scale = sfx.pitch_scale
				new_2D_audio.pitch_scale += randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			new_2D_audio.finished.connect(sfx.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			
			new_2D_audio.play()
	else:
		push_warning("SFX type not found: ", sfx_type)


func create_audio(sfx_type: SoundEffectSettings.SOUND_EFFECT_TYPE, play_while_paused: bool = false):
	if sfx_type in sound_effect_dict:
		var sfx:SoundEffectSettings = sound_effect_dict[sfx_type]
		if !sfx.has_reached_limit():
			sfx.update_audio_count(1)
			var new_audio := AudioStreamPlayer.new()
			add_child(new_audio)
			
			new_audio.stream = sfx.sound_effect
			new_audio.volume_db = linear_to_db(db_to_linear(sfx.volume) * _volume_multiplier)
			new_audio.pitch_scale = sfx.pitch_scale
			new_audio.pitch_scale += randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			new_audio.finished.connect(sfx.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			
			if play_while_paused:
				new_audio.process_mode = Node.PROCESS_MODE_ALWAYS
			
			new_audio.play()
	
