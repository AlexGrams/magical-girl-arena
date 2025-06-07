extends Node
## Applies settings to the game when the game starts up or when they are changed.


## ConfigFile containing the current game settings.
var _settings: ConfigFile = ConfigFile.new()


func get_settings() -> ConfigFile:
	return _settings


func set_settings(settings: ConfigFile) -> void:
	_settings = settings


## Changes the current display mode.
func apply_display_mode(display_mode: DisplayServer.WindowMode):
	DisplayServer.window_set_mode(display_mode)


## Changes the current volume multiplier setting.
func apply_volume(volume: float):
	AudioManager.set_volume_multiplier(volume)
