class_name ArtifactDataFireRate
extends ArtifactData


## Returns false if none of the player's powerups have the "ProjectileFireRate" type.
func can_acquire() -> bool:
	for powerup: Powerup in GameState.get_local_player().powerups:
		if powerup.has_type(Powerup.Type.ProjectileFireRate):
			return true
	
	return false
