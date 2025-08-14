class_name UpgradeAnyPowerupButton
extends Button
## Button to add or upgrade any powerup.


@export var _texture: TextureRect = null

var _powerup: PowerupData = null


func set_powerup(powerup: PowerupData):
	_powerup = powerup
	_texture.texture = powerup.sprite


func _ready() -> void:
	button_down.connect(func():
		GameState.get_local_player().upgrade_or_grant_powerup(_powerup)
	)
