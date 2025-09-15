extends Artifact


func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	for powerup: Powerup in artifact_owner.powerups:
		if powerup.has_type(Powerup.Type.Energy):
			powerup.boost_energy()
	
	artifact_owner.powerup_added.connect(func(powerup: Powerup):
		if powerup.has_type(Powerup.Type.Energy):
			powerup.boost_energy()
	)
