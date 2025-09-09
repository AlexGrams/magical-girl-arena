class_name PowerupCriticalArtifactData
extends ArtifactData
## Contains custom check for the Powerup Critical Charm's unique acquisition condition.


var powerup_index_to_make_crit: int = 0
var _local_player: PlayerCharacterBody2D = null


## Randomly selects a Powerup that the local player owns to upgrade and updates the display text.
## Upgrading a powerup gives it the ability to crtically hit.
func get_upgrade_description(_level: int = 0) -> String:
	var crit_powerup_choices: Array[int] = []
	_local_player = GameState.get_local_player()
	
	for i in range(len(_local_player.powerups)):
		if _local_player.powerups[i].crit_chance <= 0.0:
			crit_powerup_choices.append(i)
	
	crit_powerup_choices.shuffle()
	powerup_index_to_make_crit = crit_powerup_choices[0]
	_description = _local_player.powerups[powerup_index_to_make_crit].powerup_name + " has a random chance to do critical damage."
	
	return _description


## Returns false if all of the player's powerups already have critical hits enabled.
func can_acquire() -> bool:
	for powerup: Powerup in GameState.get_local_player().powerups:
		if powerup.crit_chance <= 0.0:
			return true
	
	return false
