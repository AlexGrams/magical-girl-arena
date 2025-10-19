extends Node2D
class_name DesertMapPiece

## The place where players who are on a falling map piece are teleported to.
const MAP_CENTER: Vector2 = Vector2(1020, 2370)

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
## For detecting player overlaps
@export var _area:Area2D = null
## For preventing player movement
@export var _collider:Node2D = null
var _original_base_scale:Vector2
var _has_fallen:bool = false
## True if this piece will not come back after it has fallen.
var _permanent:bool = false
## Collision layer that the piece should have when it has fallen.
var _area_collision_layer:int = 0

## Emitted once this piece has risen back to its starting position.
signal returned(piece: DesertMapPiece)


func get_has_fallen() -> bool:
	return _has_fallen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_original_base_scale = base.scale
	_reset_cracks()
	_collider.disabled = true
	_area_collision_layer = _area.collision_layer
	_area.collision_layer = 0


## Returns true if there is at least one player on this piece.
func has_player() -> bool:
	return _area.has_overlapping_areas()


## Call to begin the process for cracking, falling, and returning this map piece.
@rpc("authority", "call_local")
func initiate_falling(permanent: bool = false) -> void:
	if permanent:
		_permanent = permanent
	if _has_fallen:
		return
	
	_has_fallen = true
	# How long between cracks
	var crack_interval:float = time_to_crack/float(total_crack_num)
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.DESERT_CRACKING, true, time_to_crack + crack_interval)
	for i in total_crack_num:
		var scale_size:float = float(i + 1) / total_crack_num
		clip_mask.scale = Vector2(scale_size, scale_size)
		# Scale is the reciprocal, because cracks is a child of clip_mask
		# We don't want cracks to scale with clip_mask
		cracks.scale = Vector2(1.0/scale_size, 1.0/scale_size)
		await get_tree().create_timer(crack_interval, false).timeout
	await get_tree().create_timer(crack_interval, false).timeout
	_fall()

## Animate and remove this piece from the map.
func _fall() -> void:
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.DESERT_FALLING, true, fall_time)
	_collider.disabled = false
	_area.collision_layer = _area_collision_layer
	
	# If the local player is touching this piece, instakill them and teleport them to the 
	# center of the map.
	for area: Area2D in _area.get_overlapping_areas():
		var other: Node = area.get_parent()
		if other != null:
			if other == GameState.get_local_player():
				# Kill player, have them visually fall, then teleport
				other.kill()
				other.set_is_invulnerable(true)
				var tween = create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				var original_scale = other.scale
				tween.tween_property(other, "scale", Vector2.ZERO, 0.5)
				tween.tween_callback(func(): 
					await get_tree().create_timer(0.5, false).timeout
					other.teleport(MAP_CENTER)
					other.set_is_invulnerable(false)
				)
				tween.tween_property(other, "scale", original_scale, 0.5)
			elif other is HealthOrb:
				# Hide health orbs that were over the piece when it fell.
				other.hide()
	
	# Animation
	var tween_fall = create_tween()
	tween_fall.set_ease(Tween.EASE_OUT)
	tween_fall.set_trans(Tween.TRANS_EXPO)
	tween_fall.set_parallel()
	tween_fall.tween_property(base, "scale", Vector2.ZERO, fall_time)
	#tween_fall.tween_property(base, "modulate", Color.html("241a13"), fall_time)
	#for child in triangles.get_children():
		#child.scale = Vector2.ZERO
	await get_tree().create_timer(time_to_crack + fall_time + 5, false).timeout
	
	# Don't come back if this piece should be removed permanently.
	if not _permanent:
		rise()

## Animate and return this piece to the map.
@rpc("authority", "call_local")
func rise() -> void:
	# Adding 1 second so you can hear the dust sound settle in
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.DESERT_RISING, true, rise_time + 1)
	_reset_cracks()
	_has_fallen = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_parallel()
	tween.tween_property(base, "scale", _original_base_scale, rise_time)
	tween.tween_property(base, "modulate", Color.WHITE, rise_time)
	await get_tree().create_timer(rise_time, false).timeout
	
	_collider.disabled = true
	_area.collision_layer = 0
	returned.emit(self)

# Hide cracks again
func _reset_cracks() -> void:
	clip_mask.scale = Vector2.ZERO
	cracks.scale = Vector2.ONE
