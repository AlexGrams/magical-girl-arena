extends Control

## The volume multiplayer that a value of "1.0" on the volume slider represents.
const max_volume_slider_value: float = 1.25

## Slider for setting the game volume.
@export var _volume_slider: Slider = null

var _screen_modes := [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_WINDOWED]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_screen_mode_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(_screen_modes[index])


func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	AudioManager.set_volume_multiplier(_volume_slider.value * max_volume_slider_value)
