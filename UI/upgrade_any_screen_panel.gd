class_name UpgradeAnyScreenPanel
extends Panel
## Allows for acquiring or upgrading any Powerup in the game.


## Folder containing all PowerupData files.
const POWERUP_DATA_PATH: String = "res://Powerups/PowerupDataResourceFiles/"

@export var _upgrade_any_screen_button_container: GridContainer = null
@export var _upgrade_any_button: String = ""


func _ready() -> void:
	var upgrade_any_button_resource: Resource = load(_upgrade_any_button)
	# Add all powerups to the screen.
	for powerup_data_file_name: String in DirAccess.open(POWERUP_DATA_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in powerup_data_file_name:
			powerup_data_file_name = powerup_data_file_name.trim_suffix('.remap')
		
		var powerup_data: PowerupData = ResourceLoader.load(POWERUP_DATA_PATH + powerup_data_file_name)
		if powerup_data != null:
			var upgrade_any_button: UpgradeAnyPowerupButton = upgrade_any_button_resource.instantiate()
			upgrade_any_button.set_powerup(powerup_data)
			_upgrade_any_screen_button_container.add_child(upgrade_any_button, true)
