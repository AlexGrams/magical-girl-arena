extends Artifact


func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	for powerup: Powerup in artifact_owner.powerups:
		if powerup.has_type(Powerup.Type.AreaSize):
			powerup.boost_area_size()
	
	artifact_owner.powerup_added.connect(func(powerup: Powerup):
		if powerup.has_type(Powerup.Type.AreaSize):
			powerup.boost_area_size()
	)
