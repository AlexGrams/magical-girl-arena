extends Artifact
## Bullets created from ultimate ability have a random chance to do double damage.


## Chance of ultimate ability criting after getting this Artifact. 
@export_range(0, 1) var _crit_chance = 0.25


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Set up this artifact's passive 
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner.set_ultimate_crit_chance(_crit_chance)
