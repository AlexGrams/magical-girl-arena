extends Sprite2D
## Used to call SFX for Corvus's idle animation (flapping wings)

## Boolean is needed so that SFX does not playing during spawn in
@export var is_playing: bool = false

func play_flap_sfx():
	if is_playing:
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CORVUS_FLAP_WING)

func play_idle_anim():
	$AnimationPlayer.play("Corvus_Idle")

func stop_idle_anim():
	$AnimationPlayer.stop()
