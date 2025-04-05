extends EXPOrb


# Destroys this object and adds gold. Called when gold touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if uncollected and is_multiplayer_authority() and area.get_collision_layer_value(4):
		uncollected = false
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_GOLD_PICKUP)
		GameState.collect_gold.rpc()
		destroy.rpc_id(1) 
