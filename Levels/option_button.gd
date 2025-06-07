extends OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Removes the gray panel that appears behind popup menus in option buttons
	var dropdown_popup : PopupMenu = get_popup()
	dropdown_popup.transparent_bg = true
