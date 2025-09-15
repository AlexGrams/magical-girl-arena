class_name ArtifactDataEnergy
extends ArtifactData


## Returns false if none of the player's powerups have the "Energy" type.
func can_acquire() -> bool:
	for powerup: Powerup in GameState.get_local_player().powerups:
		if powerup.has_type(Powerup.Type.Energy):
			return true
	
	return false
