extends Button

@export var label:Label
var original_scale:Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if label != null:
		original_scale = label.scale
	else:
		push_warning("Label has not been set")

func _on_mouse_entered():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", original_scale * 1.10, 0.1)

func _on_mouse_exited():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", original_scale, 0.1)
