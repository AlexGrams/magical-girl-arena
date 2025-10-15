extends AudioStreamPlayer2D

var sfx_duration: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make sure SFX length matches status length
	pitch_scale = (stream.get_length() / sfx_duration)
	play()
	await finished
	queue_free()
