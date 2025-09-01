extends Node2D
class_name DesertMapPiece

## How long it takes for the cracks to fully appear
@export var time_to_crack:float
## How many times it cracks. Greater increments = smaller and smoother cracking
@export var total_crack_num:int
## How long it takes to fully fall down
@export var fall_time:float
## How long it takes to rise back up (after falling)
@export var rise_time:float

## Used for clipping the cracks
@export var clip_mask:Sprite2D
@export var cracks:Sprite2D
## Regular desert layer with base color and cracks
@export var base:Sprite2D
## Node that has all of the triangles as children
@export var triangles:Node2D
var _original_base_scale:Vector2

# TESTING: _has_fallen and _time_since_last_try ARE ONLY FOR _process TESTING
var _has_fallen:bool = false
var _time_since_last_try:float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_original_base_scale = base.scale

# TESTING: _process IS BEING USED FOR TESTING ONLY. NOT NEEDED IN BUILD.
func _process(delta:float) -> void:
	_time_since_last_try += 1 * delta
	if _time_since_last_try > 1:
		var random_num = randf()
		if not _has_fallen and random_num > 0.95:
			_has_fallen = true
			initiate_falling()
			await get_tree().create_timer(time_to_crack + fall_time + 5).timeout
			rise()
			_has_fallen = false
		_time_since_last_try = 0
		

# Use to start the cracking and falling visual on its own
func initiate_falling() -> void:
	show_cracks()
	await get_tree().create_timer(time_to_crack).timeout
	fall()
	
func show_cracks() -> void:
	# How long between cracks
	var crack_interval:float = time_to_crack/float(total_crack_num)
	for i in total_crack_num:
		var scale_size:float = float(i + 1) / total_crack_num
		clip_mask.scale = Vector2(scale_size, scale_size)
		# Scale is the reciprocal, because cracks is a child of clip_mask
		# We don't want cracks to scale with clip_mask
		cracks.scale = Vector2(1.0/scale_size, 1.0/scale_size)
		await get_tree().create_timer(crack_interval).timeout

func fall() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_parallel()
	tween.tween_property(base, "scale", Vector2.ZERO, fall_time)
	tween.tween_property(base, "modulate", Color.html("241a13"), fall_time)
	for child in triangles.get_children():
		child.scale = Vector2.ZERO

func rise() -> void:
	reset_cracks()
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_parallel()
	tween.tween_property(base, "scale", _original_base_scale, rise_time)
	tween.tween_property(base, "modulate", Color.WHITE, rise_time)
	await get_tree().create_timer(rise_time).timeout
	for child in triangles.get_children():
		child.scale = Vector2.ONE

# Hide cracks again
func reset_cracks() -> void:
	clip_mask.scale = Vector2.ZERO
	cracks.scale = Vector2.ONE
