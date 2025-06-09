extends Control

## The volume multiplayer that a value of "1.0" on the volume slider represents.
const max_volume_slider_value: float = 1.25

## OptionButton for display mode.
@export var _screen_mode_option: OptionButton = null
## Slider for setting the main menu and battle music volume.
@export var _music_volume_slider: Slider = null
## Spinbox for setting the main menu and battle music volume volume
@export var _music_spinbox: SpinBox = null
## Slider for setting the sfx volume.
@export var _sfx_volume_slider: Slider = null
## Spinbox for setting the sfx volume
@export var _sfx_spinbox: SpinBox = null

var _screen_modes := [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_WINDOWED]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var settings: ConfigFile = SettingsManager.get_settings()
	_screen_mode_option.selected = _screen_modes.find(settings.get_value("display", "display_mode"))
	_sfx_volume_slider.value = settings.get_value("sound", "volume") / max_volume_slider_value
	_sfx_spinbox.value = _slider_to_spinbox_value(_sfx_volume_slider.value)
	_music_volume_slider.value = settings.get_value("music", "volume") / max_volume_slider_value
	_music_spinbox.value = _slider_to_spinbox_value(_music_volume_slider.value)


func _on_screen_mode_item_selected(index: int) -> void:
	SettingsManager.apply_display_mode(_screen_modes[index])


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
		

## Writes values set on this screen to disk.
func _save_settings_changes() -> void:
	SaveManager.save_settings(_screen_modes[_screen_mode_option.selected], _sfx_volume_slider.value * max_volume_slider_value, _music_volume_slider.value * max_volume_slider_value)

## Helper functions
func _spinbox_to_slider_value(spinbox_value: float) -> float:
	return spinbox_value / 100

func _slider_to_spinbox_value(slider_value: float) -> float:
	return slider_value * 100
