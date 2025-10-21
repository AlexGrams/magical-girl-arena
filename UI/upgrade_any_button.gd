class_name UpgradeAnyPowerupButton
extends ButtonBlockPress
## Button to add or upgrade any powerup.


@export var _texture: TextureRect = null

var _powerup: PowerupData = null
var _artifact: ArtifactData = null

signal upgrade_chosen()


func get_powerup() -> PowerupData:
	return _powerup


func set_powerup(powerup: PowerupData):
	_powerup = powerup
	_texture.texture = powerup.sprite


func set_artifact(artifact: ArtifactData) -> void:
	_artifact = artifact
	_texture.texture = artifact.sprite


func _ready() -> void:
	super()
	button_down.connect(func():
		if _powerup != null:
			GameState.get_local_player().upgrade_or_grant_powerup(_powerup)
			GameState.playground.hud_canvas_layer.upgrade_screen.add_other_player_selected_item.rpc(_powerup.name)
		if _artifact != null:
			GameState.get_local_player().add_artifact(_artifact)
			GameState.playground.hud_canvas_layer.upgrade_screen.add_other_player_selected_item.rpc(_artifact.name)
		upgrade_chosen.emit()
	)
