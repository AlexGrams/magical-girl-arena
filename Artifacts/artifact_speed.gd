extends Artifact
## Gives the player more speed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)


## Upgrades speed by three levels.
func activate(owner: PlayerCharacterBody2D) -> void:
	owner._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
	owner._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
	owner._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
