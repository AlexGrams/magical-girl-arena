@tool
extends DesertMapPiece
# Used for OCTAGON pieces


## Contains visual-only map elements such as grass, rocks, etc
@export var decor_scene:PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	base.add_child(decor_scene.instantiate())
