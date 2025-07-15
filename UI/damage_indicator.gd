class_name DamageIndicator
extends Control


const DURATION:float = 1

var time_passed:float = DURATION
## Used to increase size of damage indicator based on damage value
var scale_multiplier:float = 2
## Multiplied to texture's scale to set starting size. Only changes for smallest damage values.
var _base_scale:float = 1
## The original scale of the base image.
var _starting_texture_scale: Vector2 = Vector2.ONE
var _starting_big_sparkle_color: Color
var _starting_small_sparkle_color: Color
var _ending_big_sparkle_color: Color
var _ending_small_sparkle_color: Color
var _tween: Tween = null


func _ready() -> void:
	_starting_texture_scale = $TextureRect.scale
	_starting_big_sparkle_color = $TextureRect.self_modulate
	_starting_small_sparkle_color = $TextureRect/TextureRect2.self_modulate
	_ending_big_sparkle_color = _starting_big_sparkle_color
	_ending_small_sparkle_color = _starting_small_sparkle_color
	_ending_big_sparkle_color.a = 0.0
	_ending_small_sparkle_color.a = 0.0
	
	# Randomize the position once for each indicator.
	$TextureRect.position = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	if time_passed >= DURATION:
		hide()
		set_process(false)


## Play the twinkle animation.
func animate(pos: Vector2, damage_value: float) -> void:
	global_position = pos
	
	# Map damage value to texture size
	if damage_value <= 0:
		return
	elif damage_value > 100:
		scale_multiplier = 4
	elif damage_value > 60:
		scale_multiplier = 3
	else:
		scale_multiplier = 2
	
	if damage_value > 10:
		_base_scale = 1.0
	else:
		_base_scale = 0.25
	
	# Set initial values
	time_passed = 0.0
	$TextureRect.scale = _starting_texture_scale * _base_scale
	$TextureRect.self_modulate = _starting_big_sparkle_color
	$TextureRect/TextureRect2.self_modulate = _starting_small_sparkle_color
	
	if _tween != null:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property($TextureRect, "self_modulate", _ending_big_sparkle_color, 1.0)
	_tween.parallel().tween_property($TextureRect/TextureRect2, "self_modulate", _ending_small_sparkle_color, 1.0)
	_tween.set_trans(Tween.TRANS_ELASTIC)
	_tween.parallel().tween_property($TextureRect, "scale", $TextureRect.scale * scale_multiplier, 0.3)
	_tween.tween_property($TextureRect, "scale", Vector2.ZERO, 0.7)
	
	show()
	set_process(true)
