extends BaseButton

@export var label:Control
var original_scale:Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("button_down", _on_pressed)
	if label != null:
		original_scale = label.scale
	else:
		push_warning("Label has not been set")

func _on_mouse_entered():
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_HOVER, true)
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
