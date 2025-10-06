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

func set_to_disabled():
	$CharacterContainer/Border.self_modulate = Color.DIM_GRAY
	$CharacterContainer.self_modulate = Color.DIM_GRAY

## Check and set if this character can be selected.
func update_button_clickable() -> void:
	disabled = not Constants.CHARACTER_DATA[character].get_is_unlocked()
	if not disabled:
		set_to_unselected()
	else:
		set_to_disabled()

func _on_mouse_entered() -> void:
	if disabled:
		return
	
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_HOVER)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property($CharacterContainer, "scale", original_scale * 1.10, 0.1)

func _on_mouse_exited() -> void:
	if disabled:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property($CharacterContainer, "scale", original_scale, 0.1)

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		set_to_selected()
	else:
		set_to_unselected()

func _on_button_down() -> void:
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_PRESS)
