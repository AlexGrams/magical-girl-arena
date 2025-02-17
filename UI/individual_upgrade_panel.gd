class_name UpgradePanel
extends Panel

## PowerData for this button's currently associated Powerup. 
var _powerupdata: PowerupData = null

signal upgrade_chosen(powerupdata: PowerupData)


func set_powerup(powerupdata: PowerupData) -> void:
	_powerupdata = powerupdata
	$VBoxContainer/Label.text = powerupdata.name
	$VBoxContainer/TextureRect.texture = powerupdata.sprite
	$VBoxContainer/Label2.text = "TEMP: Upgrade description"


func _on_button_pressed() -> void:
	upgrade_chosen.emit(_powerupdata)
