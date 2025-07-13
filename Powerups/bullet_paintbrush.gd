extends BulletContinuous

# Speed that paint is laid out on the ground
@export var _paint_speed: float = 10
# Butterfly sprite that is summoned
@export var _butterfly_sprite: PackedScene

# Global position of where the paint line should end
var _ending_point: Vector2
# What the scale.x of the paint line should be once it's completed
var _final_scale: float = 0.0
# Whether or not the paint line lifetime timer should be ticking
var _death_timer_is_on: bool = false

func _ready() -> void:
	sprite.scale.x = 0.0
	# How long it takes for the paint line to get to the end
	var tween_time = _final_scale / _paint_speed
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(sprite, "scale", Vector2(_final_scale, sprite.scale.y), tween_time)
	tween.tween_callback(start_death_timer)
	
	var butterfly = _butterfly_sprite.instantiate()
	butterfly.ending_point = _ending_point
	butterfly.paint_speed = tween_time
	add_child(butterfly)
	butterfly.global_position = global_position


func _process(delta: float) -> void:
	if _death_timer_is_on:
		# After fully expanding, destroy after some time.
		death_timer += delta
		if death_timer >= lifetime and is_multiplayer_authority():
			queue_free()

func start_death_timer() -> void:
	_death_timer_is_on = true

## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or (typeof(data[0])) != TYPE_NODE_PATH	# Target node path
		or (typeof(data[1])) != TYPE_BOOL		# Has level 3 upgrade or not
	):
		push_error("Malformed bullet data.")
		return

	# Level 3 upgrade
	if data[1]:
		scale.y = scale.y * 2

	_ending_point = get_node(data[0]).global_position
	var final_direction: Vector2 = _ending_point - global_position
	# How long the paintbrush is at default scale (1, y)
	var PAINTBRUSH_STANDARD_LENGTH: float = abs(sprite.offset.x) * 2
	_final_scale = final_direction.length() / PAINTBRUSH_STANDARD_LENGTH
	
	rotation = final_direction.angle()
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		_modify_collider_to_harm_players()
	
	# Disable process and collision signals for non-owners.
	if not is_multiplayer_authority():
		set_physics_process(false)
