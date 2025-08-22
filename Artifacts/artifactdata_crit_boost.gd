class_name ArtifactDataCritBoost
extends ArtifactData
## Increases crit chance and multiplier. Will only appear as an option if the player has a powerup
## that can crit.


## Returns false if none of the player's powerups can crit.
func can_acquire() -> bool:
	for powerup: Powerup in GameState.get_local_player().powerups:
		if powerup.crit_chance > 0.0:
			return true
	
	return false
