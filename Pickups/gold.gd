extends EXPOrb


# Destroys this object and adds gold. Called when gold touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if uncollected and is_multiplayer_authority() and area.get_collision_layer_value(4):
		uncollected = false
		GameState.collect_gold.rpc(global_position)
		destroy.rpc_id(1) 
