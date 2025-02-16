extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = $"..".direction.angle() + deg_to_rad(90)
	
func _process(_delta) -> void:
	#rotate(45 * delta)
	pass
