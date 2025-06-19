extends Artifact
## Increases health regeneration.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Upgrades regen by five levels.
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH_REGEN)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH_REGEN)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH_REGEN)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH_REGEN)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH_REGEN)
