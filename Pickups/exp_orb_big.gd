class_name BigEXPOrb
extends EXPOrb

## How much experience is gained when collecting this big exp orb.
@export var _exp_amount: int = 1000


## Destroys orb and adds lot of EXP. Called when EXP orb touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if uncollected and is_multiplayer_authority() and area.get_collision_layer_value(4):
		uncollected = false
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_EXP_PICKUP)
		GameState.collect_exp.rpc(_exp_amount, global_position)
		destroy.rpc_id(1) 
