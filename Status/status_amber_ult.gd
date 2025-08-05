class_name StatusAmberUlt
extends Status
## Boosts owneing player's powerups for the duration that this status is applied.


func get_status_name() -> String:
	return "AmberUlt"


## Start this status effect's functionality. Only call after adding this as a child to the object
## that this status affects.
func activate() -> void:
	pass


## Get rid of the effects of this status.
func deactivate() -> void:
	pass
