class_name Powerup
extends Node2D
## Abstract class for abilities granted to the player. 

var current_level: int = 0
# The highest level that this powerup can be upgraded to.
var max_level: int = 0
var damage_levels: Array
var powerup_name := ""
# Curve describing how this powerup's main stat changes as it is upgraded.
var upgrade_curve: Curve = null

# Emitted after increasing this Powerup's level
signal powerup_level_up(new_level: int, new_damage: float)

# Meant to be overridden
func level_up():
	powerup_level_up.emit(0, 0)
	push_error("Powerup.level_up(): THIS SHOULD NOT BE ACTIVATING.")


func activate_powerup():
	push_error("Powerup.activate_powerup(): THIS SHOULD NOT BE ACTIVATING.")


func deactivate_powerup():
	push_error("Powerup.deactivate_powerup(): THIS SHOULD NOT BE ACTIVATING.")


# Set the multiplayer authority for this powerup
func set_authority(id: int) -> void:
	set_multiplayer_authority(id)
