extends Bullet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()
