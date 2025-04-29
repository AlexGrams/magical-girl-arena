class_name CharacterSelectButton
extends Button

@export var character: Constants.Character
@export var image: Texture2D
@export var unselected_border_color: Color
@export var selected_border_color: Color
@export var unselected_color: Color
@export var selected_color: Color
var original_scale: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_scale = $CharacterContainer.scale
	if button_pressed:
		set_to_selected()
	else:
		set_to_unselected()
	set_image()

func set_image():
	$CharacterContainer/Image.texture = image

func set_to_selected():
	$CharacterContainer/Border.self_modulate = selected_border_color
	$CharacterContainer.self_modulate = selected_color
	
func set_to_unselected():
	$CharacterContainer/Border.self_modulate = unselected_border_color
	$CharacterContainer.self_modulate = unselected_color

func _on_mouse_entered() -> void:
	$CharacterContainer.scale = original_scale * 1.1

func _on_mouse_exited() -> void:
	$CharacterContainer.scale = original_scale

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		set_to_selected()
	else:
		set_to_unselected()
