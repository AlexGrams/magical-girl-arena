extends Control

## The volume multiplayer that a value of "1.0" on the volume slider represents.
const max_volume_slider_value: float = 1.25

## Slider for setting the game volume.
@export var _volume_slider: Slider = null
## Spinbox for setting the game volume
@export var _spinbox: SpinBox = null

var _screen_modes := [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_WINDOWED]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_screen_mode_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(_screen_modes[index])

# Volume slider range is 0 - 1
func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	var new_slider_value = _volume_slider.value
	_spinbox.value = new_slider_value * 100
	# Changing Spinbox value will emit the value_changed signal, so we don't need to set Audio again
	#AudioManager.set_volume_multiplier(new_volume_value * max_volume_slider_value)

# Spinbox range is 0 - 100
func _on_spin_box_value_changed(spinbox_value: float) -> void:
	AudioManager.set_volume_multiplier((spinbox_value / 100) * max_volume_slider_value)
	if (spinbox_value / 100) != _volume_slider.value:
		_volume_slider.value = spinbox_value / 100
