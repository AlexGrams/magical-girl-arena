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


func apply_cursor_size(index: int) -> void:
	_settings.set_value("display", "cursor_size", index)
	match index:
		0:
			Input.set_custom_mouse_cursor(load("res://Sprites/UI/ArrowSmall.png"))
		1:
			Input.set_custom_mouse_cursor(load("res://Sprites/UI/ArrowLarge.png"))
		_:
			push_error("No mouse cursor for this setting!")


## Changes the current SFX volume multiplier setting.
func apply_volume(volume: float):
	AudioManager.set_volume_multiplier(volume)


## Changes the current MUSIC volume multiplier setting.
func apply_music_volume(volume: float):
	AudioManager.set_music_volume_multiplier(volume)


## Changes the current BULLET OPACITY for other players' bullets.
func apply_bullet_opacity(opacity: float) -> void:
	GameState.other_players_bullet_opacity = opacity


func apply_max_fps(max_fps: int) -> void:
	Engine.max_fps = max_fps


## Shows an outline of the local player's hitbox.
func apply_hitbox_visible(hitbox_visible: bool) -> void:
	GameState.hitbox_visible = hitbox_visible
