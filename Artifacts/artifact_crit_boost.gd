extends Artifact
## Increase crit chance and crit multiplier of all owned powerups that can crit. 


## Added to powerup's crit chance.
@export var _crit_chance_boost: float = 0.25
## Added to powerup's crit multiplier.
@export var _crit_multiplier_boost: float = 0.3

## Powerups that have already had their crit chances increased by this charm.
var _boosted_powerups: Array[Powerup] = []


func _ready() -> void:
	super()


## Enable crits on a Powerup.
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner.upgrade_added.connect(func():
		# Check all powerups that the player has, boosting the ones that can crit and haven't been
		# boosted already.
		for powerup: Powerup in artifact_owner.powerups:
			if powerup.crit_chance > 0.0 and powerup not in _boosted_powerups:
				_boosted_powerups.append(powerup)
				powerup.set_crit_chance(powerup.crit_chance + _crit_chance_boost)
				powerup.set_crit_multiplier(powerup.crit_multiplier + _crit_multiplier_boost)
	)
