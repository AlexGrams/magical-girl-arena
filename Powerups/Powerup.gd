class_name Powerup
extends Node2D
## Abstract class for abilities granted to the player. 

var current_level:int
var damage_levels:Array

# Emitted after increasing this Powerup's level
signal powerup_level_up(new_level: int, new_damage: float)

# Meant to be overridden
func level_up():
	powerup_level_up.emit(0, 0)
	print("Powerup.level_up(): THIS SHOULD NOT BE ACTIVATING.")

func activate_powerup():
	print("Powerup.activate_powerup(): THIS SHOULD NOT BE ACTIVATING.")
