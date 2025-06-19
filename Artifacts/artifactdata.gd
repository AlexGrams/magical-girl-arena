class_name ArtifactData
extends ItemData
## An item that provides a passive bonus when acquired.


@export var _description: String = ""


func get_upgrade_description(_level: int = 0) -> String:
	return _description
