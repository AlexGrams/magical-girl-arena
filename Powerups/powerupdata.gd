class_name PowerupData
extends ItemData
## Contains information about a powerup.


## True if this powerup requires other players to be in the game in order to function.
@export var is_multiplayer: bool = false
## Text displayed on the Powerup upgrade screen.
@export var upgrade_description: String = ""
## Text to display on the Powerup upgrade screen for levels 1 - 5, and signature (6)
## 0: Explains functionality
## 2: Level 3 upgrade
## 5: Signature functionality
@export var upgrade_description_list: Array[String]
## Collection of tags used to describe this Powerup.
@export var types: Array[Powerup.Type]


func get_upgrade_description(level: int = 0) -> String:
	return upgrade_description_list[level]
