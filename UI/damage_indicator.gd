extends Label

## Should be passed to this script so we can map value to curve
var damage_value:float = 0
const DURATION:float = 1
var time_passed:float
## Used to increase size of damage indicator based on damage value
var scale_multiplier:float = 2
## Multiplied to texture's scale to set starting size. Only changes for smallest damage values.
var _base_scale:float = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Map damage value to texture size
	if damage_value <= 0:
		queue_free()
	elif damage_value > 100:
		scale_multiplier = 4
	elif damage_value > 60:
		scale_multiplier = 3
	elif damage_value > 10:
		pass
	else:
		_base_scale = 0.25

	time_passed = 0
	
	# Set initial scale and random position
	$TextureRect.scale = $TextureRect.scale * _base_scale
	$TextureRect.position = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($TextureRect, "scale", $TextureRect.scale * scale_multiplier, 0.3)
	tween.tween_property($TextureRect, "scale", Vector2.ZERO, 0.7)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	if time_passed >= DURATION:
		queue_free()
