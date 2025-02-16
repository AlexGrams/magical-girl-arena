class_name Powerup
extends Node2D
## Abstract class for abilities granted to the player. 
## Powerups are not replicated, but their effects are. The powerup scene only exists on the 
## server, but stuff like spawning bullets or applying buffs should be done using RPCs so that
## this Powerup's functionality is seen on all clients.

var current_level: int = 0
# The highest level that this powerup can be upgraded to.
var max_level: int = 0
var damage_levels: Array
var powerup_name := ""
# Curve describing how this powerup's main stat changes as it is upgraded.
var upgrade_curve: Curve = null

# True when this powerup harms enemies, false when it harms players.
var _is_owned_by_player := true

# Emitted after increasing this Powerup's level
signal powerup_level_up(new_level: int, new_damage: float)


func set_is_owned_by_player(value: bool) -> void:
	_is_owned_by_player = value


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
