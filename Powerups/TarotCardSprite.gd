extends Sprite2D

@export var degree_offset:float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = $"..".direction.angle() + deg_to_rad(degree_offset)
	
func _process(_delta) -> void:
	#rotate(45 * delta)
	pass
