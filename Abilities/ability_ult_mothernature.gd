extends Ability


func _ready() -> void:
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	AudioManager.create_audio_at_location.rpc(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_SWEET_ULTIMATE)


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	pass
