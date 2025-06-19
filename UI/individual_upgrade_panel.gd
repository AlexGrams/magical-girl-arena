class_name UpgradePanel
extends Control


var _health_icon_texture: Texture2D = preload("uid://b4meuc223cj41")
var _regen_icon_texture: Texture2D = preload("uid://b62tnt1mxuchm")
var _speed_icon_texture: Texture2D = preload("uid://dr7qvwfxxl54h")
var _pickup_icon_texture: Texture2D = preload("uid://cnbo4juf7220o")

var _itemdata: ItemData = null
## PowerData for this button's currently associated Powerup. This being null indicates that 
## the button upgrades a stat instead.
var _powerupdata: PowerupData = null
var _stat: Constants.StatUpgrades = Constants.StatUpgrades.HEALTH

signal upgrade_chosen(itemdata: ItemData)
signal upgrade_powerup_chosen(powerupdata: PowerupData)
signal upgrade_stat_chosen(stat: Constants.StatUpgrades)


## Displays which Powerup or Stat this button will upgrade when clicked.
func set_upgrade(upgrade: ItemData, level_dictionary: Dictionary) -> void:
	_itemdata = upgrade
	_set_display(
			_itemdata.name, 
			_itemdata.sprite, 
			_itemdata.get_upgrade_description(level_dictionary[_itemdata.name])
	)


## Set up the text and image that appears on this button depending on what it upgrades. 
func _set_display(upgrade_name: String, texture: Texture2D, description: String):
	$Box/VBoxContainer/Name_Label.text = upgrade_name
	$Box/VBoxContainer/TextureRect.texture = texture
	$Box/VBoxContainer/MarginContainer/Description_Label.text = description


func _on_button_pressed() -> void:
	if _itemdata != null:
		upgrade_chosen.emit(_itemdata)
	else:
		upgrade_stat_chosen.emit(_stat)
