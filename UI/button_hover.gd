class_name ButtonHover
extends BaseButton
## A button that does a growing and shrinking animation when you hover over it.


@export var label:Control
@export var texture:TextureRect = null
@export var text:Label = null

var original_scale:Vector2


## True if this button should be clickable, false otherwise. Changes the displayed texture to match.
func set_interactable(interactable: bool) -> void:
	disabled = not interactable
	if texture != null:
		if disabled:
			texture.modulate = Color.DIM_GRAY
		else:
			texture.modulate = Color.WHITE


## Set the text on this button's label.
func set_text(new_text: String) -> void:
	text.text = new_text


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("button_down", _on_pressed)
	if label != null:
		original_scale = label.scale
	else:
		push_warning("Label has not been set")

func _on_mouse_entered():
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_HOVER)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", original_scale * 1.10, 0.1)

func _on_mouse_exited():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", original_scale, 0.1)

func _on_pressed():
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_PRESS)
