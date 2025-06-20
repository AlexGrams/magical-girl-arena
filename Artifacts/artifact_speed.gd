extends Artifact
## Gives the player more speed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	set_process(false)


## Upgrades speed by three levels.
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
