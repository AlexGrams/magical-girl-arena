class_name StatUpgradeElement
extends HBoxContainer
## For upgrading a player stat.
## Code flow when this button is pressed: 
## 1. stat_upgrade_chosen emitted
## 2. upgrade_screen_panel hides itself and emits another signal
## 3. Player is notified through the previous signal about which upgrade was chosen.

@export var upgrade_button: Button = null
@export var stat_name: Label = null
@export var stat_level: Label = null

## Which stat this button upgrades
var _stat_type: Constants.StatUpgrades

signal stat_upgrade_chosen(stat_type: Constants.StatUpgrades)


func _ready() -> void:
	pass # Replace with function body.


## Set which stat this element upgrades.
func setup_stat_upgrade(stat_type: Constants.StatUpgrades, current_level: int) -> void:
	_stat_type = stat_type
	stat_level.text = str(current_level)
	
	match _stat_type:
		Constants.StatUpgrades.HEALTH:
			stat_name.text = "Health"
		Constants.StatUpgrades.HEALTH_REGEN:
			stat_name.text = "Health Regen"
		Constants.StatUpgrades.SPEED:
			stat_name.text = "Speed"
		Constants.StatUpgrades.PICKUP_RADIUS:
			stat_name.text = "Pickup Range"
		Constants.StatUpgrades.DAMAGE:
			stat_name.text = "Damage"
		Constants.StatUpgrades.ULTIMATE_DAMAGE:
			stat_name.text = "Ultimate Damage"
		Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
			stat_name.text = "Ultimate Charge Rate"
		_:
			push_error("No functionality for this stat upgrade type")


func _on_upgrade_button_pressed() -> void:
	stat_upgrade_chosen.emit(_stat_type)
