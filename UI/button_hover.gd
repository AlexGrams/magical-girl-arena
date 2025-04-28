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
	label.scale = original_scale * 1.10

func _on_mouse_exited():
	label.scale = original_scale
