extends GPUParticles2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Explosion set")
	emitting = true

func _on_finished() -> void:
	print("Deleting explosion")
	queue_free()
