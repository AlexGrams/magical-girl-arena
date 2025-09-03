@tool
extends DesertMapPiece
# Used for OCTAGON pieces
# Octagon pieces have an abyss piece for each of the 8 
# cardinal and intercardinal directions

enum hide_type {SHOW_ALL, HIDE_NORTH_EAST, HIDE_NORTH_WEST, HIDE_SOUTH_EAST, HIDE_SOUTH_WEST, HIDE_NORTH, HIDE_WEST, HIDE_SOUTH, HIDE_EAST}

# All of these have a set function so that the setup triangles runs in the editor

@export var hidden_type:hide_type = hide_type.SHOW_ALL : 
	set(value):
		hidden_type = value
		setup_triangles()

## Contains visual-only map elements such as grass, rocks, etc
@export var decor_scene:PackedScene

@export_group("Triangles")
@export var tri_n:Sprite2D
@export var tri_ne:Sprite2D
@export var tri_e:Sprite2D
@export var tri_se:Sprite2D
@export var tri_s:Sprite2D
@export var tri_sw:Sprite2D
@export var tri_w:Sprite2D
@export var tri_nw:Sprite2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	setup_triangles()
	base.add_child(decor_scene.instantiate())
	

func setup_triangles():
	if triangles != null:
		for child in triangles.get_children():
			child.show()
		
		# Hide the correct sides
		match hidden_type:
			hide_type.HIDE_NORTH_EAST:
				tri_ne.hide()
				tri_n.hide()
				tri_e.hide()
			hide_type.HIDE_NORTH_WEST:
				tri_nw.hide()
				tri_n.hide()
				tri_w.hide()
			hide_type.HIDE_SOUTH_EAST:
				tri_se.hide()
				tri_s.hide()
				tri_e.hide()
			hide_type.HIDE_SOUTH_WEST:
				tri_sw.hide()
				tri_s.hide()
				tri_w.hide()
			hide_type.HIDE_NORTH:
				tri_n.hide()
			hide_type.HIDE_EAST:
				tri_e.hide()
			hide_type.HIDE_SOUTH:
				tri_s.hide()
			hide_type.HIDE_WEST:
				tri_w.hide()
