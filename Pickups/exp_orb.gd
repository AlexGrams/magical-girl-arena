extends Node2D

# Ensures that this orb isn't counted multiple times by overlapping player characters.
var uncollected := true;


# Destroys orb and adds EXP. Called when EXP orb touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if uncollected and is_multiplayer_authority() and area.get_collision_layer_value(4):
		uncollected = false
		GameState.collect_exp.rpc()
		destroy.rpc_id(1)


# Delete this EXP orb on all clients. Only call on the server.
@rpc("any_peer", "call_local")
func destroy() -> void:
	self.queue_free()
