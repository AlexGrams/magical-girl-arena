class_name PowerupData
extends Resource
## Contains information about a powerup.

## The Powerup-derived scene that is spawned in after this powerup is chosen
@export var scene: Resource = null
## The name of this powerup.
@export var name := ""
## The sprite to show representing this powerup.
@export var sprite: Resource = null
## Text displayed on the Powerup upgrade screen.
@export var upgrade_description: String = ""


func get_upgrade_description() -> String:
	return upgrade_description
