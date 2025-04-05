extends Node2D

# AudioManager is used for repetitive sound effects, such as picking up experience or damaging enemies
# Script created based on this video: https://www.youtube.com/watch?v=Egf2jgET3nQ

@export var sound_effect_settings : Array[SoundEffectSettings]
var sound_effect_dict : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for sfx in sound_effect_settings:
		sound_effect_dict[sfx.type] = sfx

func create_audio_at_location(location, sfx_type: SoundEffectSettings.SOUND_EFFECT_TYPE):
	if sfx_type in sound_effect_dict:
		var sfx:SoundEffectSettings = sound_effect_dict[sfx_type]
		if !sfx.has_reached_limit():
			sfx.update_audio_count(1)
			var new_2D_audio = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			
			new_2D_audio.position = location
			new_2D_audio.stream = sfx.sound_effect
			new_2D_audio.volume_db = sfx.volume
			new_2D_audio.pitch_scale = sfx.pitch_scale
			new_2D_audio.pitch_scale += randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			new_2D_audio.finished.connect(sfx.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			
			new_2D_audio.play()
	else:
		push_warning("SFX type not found: ", sfx_type)
	
func create_audio():
	pass
	
