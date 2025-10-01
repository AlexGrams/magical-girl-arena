class_name Settings
extends Control

## The volume multiplayer that a value of "1.0" on the volume slider represents.
const max_volume_slider_value: float = 1.25

@export_group("Screens")
## Button to press to save settings and return to the previous screen.
@export var return_button: Button = null
## Button to save settings and hide this screen.
@export var hide_button: Button = null
@export var _display_screen: Control = null
@export var _audio_screen: Control = null
@export var _gameplay_screen: Control = null 

@export_group("Display")
## OptionButton for display mode.
@export var _screen_mode_option: OptionButton = null
## Checkbox for allowing for setting a limit to the max FPS.
@export var _limit_fps_checkbox: CheckBox = null
## Parent of Max FPS setting slider and spinbox.
@export var _max_fps_container: Control = null
## Slider for max FPS.
@export var _max_fps_slider: Slider = null
## Spinbox for max FPS.
@export var _max_fps_spinbox: SpinBox = null
## Dropdown for setting cursor size.
@export var _cursor_size_option: OptionButton = null

@export_group("Audio")
@export var _main_volume_slider: Slider = null
@export var _main_volume_spinbox: SpinBox = null
## Slider for setting the main menu and battle music volume.
@export var _music_volume_slider: Slider = null
## Spinbox for setting the main menu and battle music volume volume
@export var _music_spinbox: SpinBox = null
## Slider for setting the sfx volume.
@export var _sfx_volume_slider: Slider = null
## Spinbox for setting the sfx volume
@export var _sfx_spinbox: SpinBox = null
@export var _ally_powerups_volume_slider: Slider = null
@export var _ally_powerups_volume_spinbox: SpinBox = null
@export var _enemy_hit_volume_slider: Slider = null
@export var _enemy_hit_volume_spinbox: SpinBox = null
## For setting if all the damage SFX on enemies is the same.
@export var _same_hit_sfx_checkbox: CheckBox = null

@export_group("Gameplay")
## Slider for setting how transparent other players' bullets are.
@export var _bullet_opacity_slider: Slider = null
## Spinbox for setting how transparent other player' bullets are.
@export var _bullet_opacity_spinbox: SpinBox = null
## Show an outline of the player hitbox.
@export var _hitbox_visible_checkbox: CheckBox = null

## All different screens that can be shown on the settings menu.
var _setting_screens: Array[Control] = []
var _screen_modes := [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_WINDOWED]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setting_screens.append(_display_screen)
	_setting_screens.append(_audio_screen)
	_setting_screens.append(_gameplay_screen)
	switch_to_screen(0)
	
	var settings: ConfigFile = SettingsManager.get_settings()
	
	_screen_mode_option.selected = _screen_modes.find(settings.get_value("display", "display_mode"))
	_limit_fps_checkbox.button_pressed = settings.get_value("display", "limit_fps", SaveManager.DEFAULT_LIMIT_FPS)
	if not _limit_fps_checkbox.button_pressed:
		_max_fps_container.hide()
	_max_fps_slider.value = settings.get_value("display", "max_fps", SaveManager.DEFAULT_MAX_FPS)
	_max_fps_spinbox.value = _max_fps_slider.value
	_cursor_size_option.selected = settings.get_value("display", "cursor_size", 0)
	
	_main_volume_slider.value = settings.get_value("audio", "main", SaveManager.DEFAULT_MAIN_VOLUME) / max_volume_slider_value
	_main_volume_spinbox.value = _slider_to_spinbox_value(_main_volume_slider.value)
	_music_volume_slider.value = settings.get_value("music", "volume") / max_volume_slider_value
	_music_spinbox.value = _slider_to_spinbox_value(_music_volume_slider.value)
	_sfx_volume_slider.value = settings.get_value("sound", "volume") / max_volume_slider_value
	_sfx_spinbox.value = _slider_to_spinbox_value(_sfx_volume_slider.value)
	_ally_powerups_volume_slider.value = settings.get_value("audio", "ally_powerup", SaveManager.DEFAULT_ALLY_POWERUP_VOLUME) / max_volume_slider_value
	_ally_powerups_volume_spinbox.value = _slider_to_spinbox_value(_ally_powerups_volume_slider.value)
	_enemy_hit_volume_slider.value = settings.get_value("audio", "enemy_hit", SaveManager.DEFAULT_ENEMY_HIT_VOLUME) / max_volume_slider_value
	_enemy_hit_volume_spinbox.value = _slider_to_spinbox_value(_enemy_hit_volume_slider.value)
	_same_hit_sfx_checkbox.button_pressed = settings.get_value("sound", "same_hit_sfx", SaveManager.DEFAULT_SAME_HIT_SFX)
	
	_bullet_opacity_slider.value = settings.get_value("gameplay", "bullet_opacity", SaveManager.DEFAULT_BULLET_OPACITY)
	_bullet_opacity_spinbox.value = _bullet_opacity_slider.value * 100.0
	_hitbox_visible_checkbox.button_pressed = settings.get_value("gameplay", "hitbox_visible", false)


## Show a screen for a category of settings.
func switch_to_screen(screen_index: int) -> void:
	for i in range(len(_setting_screens)):
		if i == screen_index:
			_setting_screens[i].show()
		else:
			_setting_screens[i].hide()


#region Display
func _on_screen_mode_item_selected(index: int) -> void:
	SettingsManager.apply_display_mode(_screen_modes[index])


func _on_limit_fps_checkbox_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_max_fps_container.show()
		SettingsManager.apply_max_fps(round(_max_fps_spinbox.value))
	else:
		_max_fps_container.hide()
		SettingsManager.apply_max_fps(0)


func _on_max_fps_slider_drag_ended(_value_changed: bool) -> void:
	_max_fps_spinbox.value = _max_fps_slider.value


func _on_max_fps_spin_box_value_changed(spinbox_value: float) -> void:
	if _limit_fps_checkbox.button_pressed:
		SettingsManager.apply_max_fps(round(spinbox_value))
	if spinbox_value != _max_fps_slider.value:
		_max_fps_slider.value = spinbox_value


func _on_cursor_size_item_selected(index: int) -> void:
	SettingsManager.apply_cursor_size(index)
#endregion Display


#region Audio
## Main volume
func _on_main_volume_h_slider_drag_ended(_value_changed: bool) -> void:
	_main_volume_spinbox.value = _slider_to_spinbox_value(_main_volume_slider.value)


func _on_main_volume_spin_box_value_changed(value: float) -> void:
	var slider_volume = _spinbox_to_slider_value(value)
	SettingsManager.apply_main_volume(slider_volume * max_volume_slider_value)
	if slider_volume != _main_volume_slider.value:
		_main_volume_slider.value = slider_volume


## Volume Slider for MUSIC
# Volume slider range is 0 - 1
func _on_music_volume_slider_drag_ended(_value_changed: bool) -> void:
	_music_spinbox.value = _slider_to_spinbox_value(_music_volume_slider.value)


## Spinbox for MUSIC
# Spinbox range is 0 - 100
func _on_music_spin_box_value_changed(spinbox_value: float) -> void:
	var slider_volume = _spinbox_to_slider_value(spinbox_value)
	SettingsManager.apply_music_volume(slider_volume * max_volume_slider_value)
	if slider_volume != _music_volume_slider.value:
		_music_volume_slider.value = slider_volume


## Volume Slider for SFX
# Volume slider range is 0 - 1
func _on_volume_slider_drag_ended(_value_changed: bool) -> void:
	_sfx_spinbox.value = _slider_to_spinbox_value(_sfx_volume_slider.value)


## Spinbox for SFX
# Spinbox range is 0 - 100
func _on_spin_box_value_changed(spinbox_value: float) -> void:
	var slider_volume = _spinbox_to_slider_value(spinbox_value)
	SettingsManager.apply_volume(slider_volume * max_volume_slider_value)
	if slider_volume != _sfx_volume_slider.value:
		_sfx_volume_slider.value = slider_volume


## Ally Powerup volume
func _on_ally_powerups_volume_h_slider_drag_ended(_value_changed: bool) -> void:
	_ally_powerups_volume_spinbox.value = _slider_to_spinbox_value(_ally_powerups_volume_slider.value)


func _on_ally_powerups_spin_box_value_changed(value: float) -> void:
	var slider_volume = _spinbox_to_slider_value(value)
	SettingsManager.apply_ally_powerup_volume(slider_volume * max_volume_slider_value)
	if slider_volume != _ally_powerups_volume_slider.value:
		_ally_powerups_volume_slider.value = slider_volume


## Enemy Hit volume
func _on_enemy_hit_volume_h_slider_drag_ended(_value_changed: bool) -> void:
	_enemy_hit_volume_spinbox.value = _slider_to_spinbox_value(_enemy_hit_volume_slider.value)


func _on_enemy_hit_spin_box_value_changed(value: float) -> void:
	var slider_volume = _spinbox_to_slider_value(value)
	SettingsManager.apply_enemy_hit_volume(slider_volume * max_volume_slider_value)
	if slider_volume != _enemy_hit_volume_slider.value:
		_enemy_hit_volume_slider.value = slider_volume


## Checkbox for Same Hit SFX
func _on_same_hit_sfx_checkbox_toggled(toggled_on: bool) -> void:
	SettingsManager.apply_same_hit_sfx(toggled_on) 
#endregion Audio


#region Gameplay
## Slider for BULLET OPACITY 
func _on_bullet_opacity_slider_drag_ended(_value_changed: bool) -> void:
	_bullet_opacity_spinbox.value = _bullet_opacity_slider.value * 100


## Spinbox for BULLET OPACITY
func _on_bullet_opacity_spin_box_value_changed(spinbox_value: float) -> void:
	var slider_opacity: float = spinbox_value / 100.0
	SettingsManager.apply_bullet_opacity(slider_opacity)
	if slider_opacity != _bullet_opacity_slider.value:
		_bullet_opacity_slider.value = slider_opacity


## Player hitbox visibility setting was changed.
func _on_show_hitbox_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.apply_hitbox_visible(toggled_on) 
#endregion Gameplay


## Writes values set on this screen to disk.
func _save_settings_changes() -> void:
	SaveManager.save_settings(
		_screen_modes[_screen_mode_option.selected], 
		_limit_fps_checkbox.button_pressed,
		int(_max_fps_slider.value) if _limit_fps_checkbox.button_pressed else 0,
		_cursor_size_option.selected,
		
		_main_volume_slider.value * max_volume_slider_value,
		_music_volume_slider.value * max_volume_slider_value,
		_sfx_volume_slider.value * max_volume_slider_value, 
		_ally_powerups_volume_slider.value * max_volume_slider_value,
		_enemy_hit_volume_slider.value * max_volume_slider_value,
		_same_hit_sfx_checkbox.button_pressed,
		
		_bullet_opacity_slider.value,
		_hitbox_visible_checkbox.button_pressed
	)

## Helper functions
func _spinbox_to_slider_value(spinbox_value: float) -> float:
	return spinbox_value / 100

func _slider_to_spinbox_value(slider_value: float) -> float:
	return slider_value * 100
