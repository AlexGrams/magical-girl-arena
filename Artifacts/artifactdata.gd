class_name ArtifactData
extends ItemData
## An item that provides a passive bonus when acquired.


@export var _description: String = ""
## If true, only one player in the game can have this artifact at a time. Only one player will be offered
## this artifact on the upgrade screen screen at a time.
@export var is_unique: bool = false


func get_upgrade_description(_level: int = 0) -> String:
	return _description


## Returns false if special conditions for getting this Charm are not met.
func can_acquire() -> bool:
	return true
