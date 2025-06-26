extends EXPOrb


# Destroys this object and adds gold. Called when gold touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	var hit_node: Node = area.get_parent()
	if uncollected and hit_node != null and hit_node.is_in_group("player"):
		uncollected = false
		GameState.collect_gold.rpc(global_position)
		destroy()
