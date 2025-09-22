extends Node
## Applies settings to the game when the game starts up or when they are changed.


## ConfigFile containing the current game settings.
var _settings: ConfigFile = ConfigFile.new()


func get_settings() -> ConfigFile:
	return _settings


func set_settings(settings: ConfigFile) -> void:
	_settings = settings

#region Display
## Changes the current display mode.
func apply_display_mode(display_mode: DisplayServer.WindowMode):
	DisplayServer.window_set_mode(display_mode)


func apply_limit_fps(_value: bool) -> void:
	pass


func apply_max_fps(max_fps: int) -> void:
	Engine.max_fps = max_fps


func apply_cursor_size(index: int) -> void:
	_settings.set_value("display", "cursor_size", index)
	match index:
		0:
			Input.set_custom_mouse_cursor(load("res://Sprites/UI/ArrowSmall.png"))
		1:
			Input.set_custom_mouse_cursor(load("res://Sprites/UI/ArrowLarge.png"))
		_:
			push_error("No mouse cursor for this setting!")
#endregion Display


#region Audio
func apply_main_volume(volume: float) -> void:
	AudioManager.update_bus_volume(volume, "Master")


## Changes the current MUSIC volume multiplier setting.
func apply_music_volume(volume: float):
	AudioManager.update_bus_volume(volume, "Music")


## Changes the current SFX volume multiplier setting.
func apply_volume(volume: float):
	AudioManager.update_bus_volume(volume, "SFX")


func apply_ally_powerup_volume(volume: float) -> void:
	AudioManager.update_bus_volume(volume, "Ally_Powerups")


func apply_enemy_hit_volume(volume: float) -> void:
	AudioManager.update_bus_volume(volume, "Enemy_Hits")


## Changes if all Enemy damage SFX is the same sound.
func apply_same_hit_sfx(value: bool) -> void:
	AudioManager.set_use_same_enemy_hit_sfx(value)
#endregion Audio


#region Gameplay
## Changes the current BULLET OPACITY for other players' bullets.
func apply_bullet_opacity(opacity: float) -> void:
	GameState.other_players_bullet_opacity = opacity


## Shows an outline of the local player's hitbox.
func apply_hitbox_visible(hitbox_visible: bool) -> void:
	GameState.hitbox_visible = hitbox_visible
#endregion Gameplay
