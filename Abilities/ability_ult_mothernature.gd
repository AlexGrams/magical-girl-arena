extends Ability


@export var _bullet_scene: String = ""
## How long the ult lasts.
@export var _duration: float = 10.0

## Current damage per frame.
var _damage: float = 0.0
var _damage_curve: Curve = preload("res://Curves/Abilities/ability_ult_mothernature.tres")


func _ready() -> void:
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	AudioManager.create_audio_at_location.rpc(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.MOTHERNATURE_ULTIMATE)
	GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
		1, 
		[
			_bullet_scene, 
			global_position, 
			Vector2.ZERO, 
			_damage, 
			false,
			true,
			-1,
			-1,
			[
				_duration
			]
		]
	)


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	_damage = _damage_curve.sample(float(_level) / GameState.MAX_LEVEL)
