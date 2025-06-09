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
## Text to display on the Powerup upgrade screen for levels 1 - 5, and signature (6)
## 0: Explains functionality
## 2: Level 3 upgrade
## 5: Signature functionality
@export var upgrade_description_list: Array[String]

func get_upgrade_description() -> String:
	return upgrade_description
