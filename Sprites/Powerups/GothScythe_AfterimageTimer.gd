extends Sprite2D

var time_elapsed = 0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	if (time_elapsed > 1):
		queue_free()
