class_name HealthOrb
extends EXPOrb
## A pickup that adds health to a player.

## How much health the player gets.
@export var HEALTH_TO_ADD: float = 25.0


## Destroys this object and adds health. Called when it touches any player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if (uncollected 
		and multiplayer.get_unique_id() == area.get_multiplayer_authority() 
		and other is PlayerCharacterBody2D
	):
		uncollected = false
		other.take_damage.rpc(-abs(HEALTH_TO_ADD))
		destroy.rpc_id(1) 


## Does nothing to prevent this orb type from gravitating. Should not be called.
@rpc("any_peer", "call_local")
func set_player(_new_player: NodePath) -> void:
	pass
