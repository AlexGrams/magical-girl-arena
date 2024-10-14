extends Node2D

class_name Powerup

var current_level:int
var damage_levels:Array

# Meant to be overridden
func level_up():
	current_level += 1
