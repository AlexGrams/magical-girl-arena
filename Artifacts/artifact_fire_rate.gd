extends Artifact


func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	for powerup: Powerup in artifact_owner.powerups:
		if powerup.has_type(Powerup.Type.ProjectileFireRate):
			powerup.boost_fire_rate()
	
	artifact_owner.powerup_added.connect(func(powerup: Powerup):
		powerup.boost_fire_rate()
	)
