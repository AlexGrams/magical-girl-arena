extends Ability


@export var _duration: float = 10.0
## Used to attach fire SFX node to player
@export var _audio_player_scene: PackedScene

var _owner: PlayerCharacterBody2D = null


func _ready() -> void:
	super()
	
	_owner = get_parent()


func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	var amber_ult_status: StatusAmberUlt = StatusAmberUlt.new()
	amber_ult_status.duration = _duration
	_owner.add_status(amber_ult_status)
	
	# Play activation sound, then continue with passive fire sound
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.AMBER_ULTIMATE)
	var _new_audio_player = _audio_player_scene.instantiate()
	_new_audio_player.sfx_duration = _duration
	_owner.add_child(_new_audio_player)
	#AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.AMBER_ULTIMATE_DURATION, true, _duration)

## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	pass
