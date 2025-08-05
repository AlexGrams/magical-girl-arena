class_name StatusAmberUlt
extends Status
## Boosts owneing player's speed and powerups for the duration that this status is applied.


var _owning_player: PlayerCharacterBody2D = null


func get_status_name() -> String:
	return "AmberUlt"


## Start this status effect's functionality. Only call after adding this as a child to the object
## that this status affects.
func activate() -> void:
	if get_parent() is PlayerCharacterBody2D:
		_owning_player = get_parent()
		for powerup: Powerup in _owning_player.powerups:
			powerup.boost()
		
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)


## Get rid of the effects of this status.
func deactivate() -> void:
	if _owning_player != null:
		for powerup: Powerup in _owning_player.powerups:
			powerup.unboost()
		
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
