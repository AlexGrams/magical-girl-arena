extends Label

@onready var _shadow:Label = $Shadow
@onready var _outline:Label = $Outline

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up shadow and outline text to match main label
	_set_text_settings(_shadow)
	_set_text_settings(_outline)
	_outline.add_theme_constant_override("outline_size", get_theme_constant("outline_size"))
	
	# Remove shadow and outline from main label
	add_theme_constant_override("shadow_offset_x", 0)
	add_theme_constant_override("shadow_offset_y", 0)
	add_theme_constant_override("outline_size", 0)
	add_theme_constant_override("shadow_outline_size", 0)
	
	# Shadow and outline are hidden at first to make building UI simpler in editor
	_shadow.show()
	_outline.show()

# Use change_text instead of setting text directly
func change_text(new_text:String) -> void:
	text = new_text
	_shadow.text = text
	_outline.text = text

func _set_text_settings(label:Label) -> void:
	label.text = text
	label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	label.horizontal_alignment = horizontal_alignment
	label.vertical_alignment = vertical_alignment
	label.autowrap_mode = autowrap_mode
