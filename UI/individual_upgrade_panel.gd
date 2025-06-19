class_name UpgradePanel
extends Control


## ItemData for this button's currently associated item. Can be an Artifact or a Powerup.
var _itemdata: ItemData = null
var _stat: Constants.StatUpgrades = Constants.StatUpgrades.HEALTH

signal upgrade_chosen(itemdata: ItemData)
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
