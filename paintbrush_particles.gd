extends GPUParticles2D

var length:float
var paint_speed:float = 5.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set visibility box
	visibility_rect.size.x = length * 2
	var final_box = Vector3(length, process_material.emission_box_extents.y, 1)
	var final_offset = Vector3(length, process_material.emission_shape_offset.y, 1)
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(process_material, "emission_box_extents", final_box, paint_speed)
	tween.tween_property(process_material, "emission_shape_offset", final_offset, paint_speed)
