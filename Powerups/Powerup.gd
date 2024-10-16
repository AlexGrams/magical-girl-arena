extends Node2D

class_name Powerup

var current_level:int
var damage_levels:Array

# Meant to be overridden
func level_up():
	print("Powerup.level_up(): THIS SHOULD NOT BE ACTIVATING.")

func activate_powerup():
	print("Powerup.activate_powerup(): THIS SHOULD NOT BE ACTIVATING.")
