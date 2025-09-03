extends DesertMapPiece
# Used for DIAMOND shaped pieces
# Diamond shapes pieces need their decor rotated properly

## Node that holds all of the decor (grass tuft) sprites
@export var decor:Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	for grass in decor.get_children():
		grass.rotation = -rotation
