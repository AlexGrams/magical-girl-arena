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
	_sfx_spinbox.value = _sfx_volume_slider.value * 100


func _on_screen_mode_item_selected(index: int) -> void:
	SettingsManager.apply_display_mode(_screen_modes[index])


# Volume slider range is 0 - 1
func _on_volume_slider_drag_ended(_value_changed: bool) -> void:
	var new_slider_value = _sfx_volume_slider.value
	_sfx_spinbox.value = new_slider_value * 100


# Spinbox range is 0 - 100
func _on_spin_box_value_changed(spinbox_value: float) -> void:
	SettingsManager.apply_volume((spinbox_value / 100) * max_volume_slider_value)
	if (spinbox_value / 100) != _sfx_volume_slider.value:
		_sfx_volume_slider.value = spinbox_value / 100


## Writes values set on this screen to disk.
func _save_settings_changes() -> void:
	SaveManager.save_settings(_screen_modes[_screen_mode_option.selected], _sfx_volume_slider.value * max_volume_slider_value)
