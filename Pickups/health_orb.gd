class_name HealthOrb
extends EXPOrb
## A pickup that adds health to a player.

## How much health the player gets.
@export var HEALTH_TO_ADD: float = 25.0


## Destroys this object and adds health. Called when it touches any player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if uncollected and multiplayer.get_unique_id() == player.get_multiplayer_authority()and area.get_collision_layer_value(4):
		uncollected = false
		if player is PlayerCharacterBody2D:
			player.take_damage.rpc(-abs(HEALTH_TO_ADD))
		destroy.rpc_id(1) 
