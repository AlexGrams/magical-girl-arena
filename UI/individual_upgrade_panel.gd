class_name UpgradePanel
extends Control


var _health_icon_texture: Texture2D = preload("uid://b4meuc223cj41")
var _regen_icon_texture: Texture2D = preload("uid://b62tnt1mxuchm")
var _speed_icon_texture: Texture2D = preload("uid://dr7qvwfxxl54h")
var _pickup_icon_texture: Texture2D = preload("uid://cnbo4juf7220o")

## PowerData for this button's currently associated Powerup. This being null indicates that 
## the button upgrades a stat instead.
var _powerupdata: PowerupData = null
var _stat: Constants.StatUpgrades = Constants.StatUpgrades.HEALTH

signal upgrade_powerup_chosen(powerupdata: PowerupData)
signal upgrade_stat_chosen(stat: Constants.StatUpgrades)


## Displays which Powerup or Stat this button will upgrade when clicked.
func set_upgrade(upgrade) -> void:
	if upgrade is PowerupData:
		_powerupdata = upgrade
		_set_display(_powerupdata.name, _powerupdata.sprite, _powerupdata.get_upgrade_description())
	elif upgrade is Constants.StatUpgrades:
		_stat = upgrade
		_powerupdata = null
		
		match upgrade:
			Constants.StatUpgrades.HEALTH:
				_set_display("Health", _health_icon_texture, "Increase max health.")
			Constants.StatUpgrades.HEALTH_REGEN:
				_set_display("Health Regeneration", _regen_icon_texture, "Increase occasional health regen.")
			Constants.StatUpgrades.SPEED:
				_set_display("Speed", _speed_icon_texture, "Increase movement speed.")
			Constants.StatUpgrades.PICKUP_RADIUS:
				_set_display("Pickup Radius", _pickup_icon_texture, "Increase range for picking up items such as experience and health.")
			#Constants.StatUpgrades.DAMAGE:
				#_set_display("Health", stat_upgrade_texture, "Increase max health.")
			#Constants.StatUpgrades.ULTIMATE_DAMAGE:
				#_set_display("Health", stat_upgrade_texture, "Increase max health.")
			#Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
				#_set_display("Health", stat_upgrade_texture, "Increase max health.")
			_:
				push_error("No upgrade functionality for this stat upgrade type")
	else:
		push_error("No upgrade functionality for this type")


## Set up the text and image that appears on this button depending on what it upgrades. 
func _set_display(upgrade_name: String, texture: Texture2D, description: String):
	$Box/VBoxContainer/Name_Label.text = upgrade_name
	$Box/VBoxContainer/TextureRect.texture = texture
	$Box/VBoxContainer/MarginContainer/Description_Label.text = description


func _on_button_pressed() -> void:
	if _powerupdata != null:
		upgrade_powerup_chosen.emit(_powerupdata)
	else:
		upgrade_stat_chosen.emit(_stat)
