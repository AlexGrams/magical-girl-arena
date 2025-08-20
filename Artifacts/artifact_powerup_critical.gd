extends Artifact
## Makes one of the owning player's powerups able to critically hit.


func _ready() -> void:
	super()


## Enable crits on a Powerup.
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner.powerups[artifactdata.powerup_index_to_make_crit].set_crit_chance(0.25)
