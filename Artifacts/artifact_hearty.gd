extends Artifact
## Increases max HP and prevents you from dying one time only.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH)
	artifact_owner._on_stat_upgrade_chosen(Constants.StatUpgrades.HEALTH)
	
	artifact_owner.set_prevent_death.rpc(true)
	
	artifact_owner.death_prevented.connect(func():
		artifact_owner.add_temp_health.rpc(50, 30.0)
	)
