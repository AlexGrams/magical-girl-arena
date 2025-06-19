class_name ItemData
extends Resource
## Information about an object that can be acquired during a match, usually upon leveling up.


## The scene that is spawned in after this item is chosen
@export var scene: Resource = null
## The name of this item.
@export var name := ""
## The sprite to show representing this item.
@export var sprite: Resource = null


func get_upgrade_description(_level: int = 0) -> String:
	return ""
