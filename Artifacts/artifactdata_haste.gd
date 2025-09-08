class_name ArtifactDataHaste
extends ArtifactData
## Boosts Haste Powerups


func can_acquire() -> bool:
	for powerup: Powerup in GameState.get_local_player().powerups:
		if powerup.has_type(Powerup.Type.Haste):
			return true
	
	return false
