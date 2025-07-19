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


## Changes the current SFX volume multiplier setting.
func apply_volume(volume: float):
	AudioManager.set_volume_multiplier(volume)


## Changes the current MUSIC volume multiplier setting.
func apply_music_volume(volume: float):
	AudioManager.set_music_volume_multiplier(volume)


## Changes the current BULLET OPACITY for other players' bullets.
func apply_bullet_opacity(opacity: float) -> void:
	GameState.other_players_bullet_opacity = opacity
