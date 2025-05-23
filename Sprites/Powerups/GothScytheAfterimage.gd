extends Node2D

@export var scythe_sprite:PackedScene
@export var base_sprite:Sprite2D
var time_elapsed = 0.25

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= 0.05:
		create_afterimage()
		time_elapsed = 0

func create_afterimage():
	var new_afterimage = scythe_sprite.instantiate()
	new_afterimage.offset = base_sprite.offset
	new_afterimage.global_position = base_sprite.global_position
	new_afterimage.global_rotation = base_sprite.global_rotation
	new_afterimage.scale = base_sprite.scale * scale * get_parent().scale
	new_afterimage.flip_h = base_sprite.flip_h
	add_child(new_afterimage)
