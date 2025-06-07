extends Control

var _screen_modes := [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_WINDOWED]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_screen_mode_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(_screen_modes[index])
