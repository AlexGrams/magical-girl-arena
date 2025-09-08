class_name ButtonBlockPress
extends BaseButton
## A button that looks like a physical keyboard button.

## Button visuals (not including shadow) (the top face of a physical button)
@export var box:Control
## The height of the edge of the button (AKA the offset between box and shadow)
@export var height:float
## Holds the text for the button
@export var label:Label

@onready var original_position:Vector2 = box.position
## Whether or not the button has been pressed
var is_being_pressed:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("button_down", _on_button_down)
	connect("button_up", _on_button_up)
	connect("mouse_entered", _on_button_hover)
	connect("mouse_exited", _on_button_hover_exit)

func set_interactable(is_interactable:bool) -> void:
	disabled = not is_interactable
	if disabled:
		box.modulate = Color.DIM_GRAY
	else:
		box.modulate = Color.WHITE

## Set the text on this button's label.
func set_new_text(new_text: String) -> void:
	if label != null:
		label.text = new_text

func _on_button_hover() -> void:
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_HOVER, true)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(box, "position", original_position - Vector2(0, height), 0.15)

func _on_button_hover_exit() -> void:
	if not is_being_pressed:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(box, "position", original_position, 0.15)

func _on_button_down() -> void:
	is_being_pressed = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(box, "position", original_position + Vector2(0, height), 0.15)


func _on_button_up() -> void:
	is_being_pressed = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(box, "position", original_position, 0.15)
