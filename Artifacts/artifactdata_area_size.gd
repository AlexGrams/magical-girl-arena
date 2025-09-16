class_name ArtifactDataAreaSize
extends ArtifactData


## Returns false if none of the player's powerups have the "Area Size" type.
func can_acquire() -> bool:
	for powerup: Powerup in GameState.get_local_player().powerups:
		if powerup.has_type(Powerup.Type.AreaSize):
			return true
	
	return false
