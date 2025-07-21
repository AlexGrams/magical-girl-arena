extends Node2D

# Global position where the butterfly should finish landing
var ending_point: Vector2
# How long it takes to get to the end of the paint line
var paint_speed: float = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(self, "global_position", ending_point, paint_speed)
	tween.tween_property(self, "modulate", Color.html("ffffff00"), 0.5)
	tween.tween_callback(queue_free)
