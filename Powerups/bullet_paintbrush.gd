extends BulletContinuous


@export var _paintbrush: Node2D = null

## The location of the starting end of the paint line.
var _startpoint: Vector2 = Vector2.ZERO
## The bullet's scale in the X-axis when it is done stretching.
var _target_scale: float = 0.0
## The bullet's position when it is done stretching.
var _target_position: Vector2 = Vector2.ZERO
## How much the scale of the bullet should change per second as a percentage of its desired scale.
var _scale_percentage_rate: float = 0.0
## How long the bullet has been stretching for as a percentage of the total time it should be stretching.
var _scale_percentage: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _scale_percentage < 1.0:
		# Expand until endpoint is reached.
		_scale_percentage += _scale_percentage_rate * delta
		_paintbrush.scale.x = lerp(1.0, _target_scale, _scale_percentage)
		global_position = lerp(_startpoint, _target_position, _scale_percentage)
	else:
		# After fully expanding, destroy after some time.
		death_timer += delta
		if death_timer >= lifetime and is_multiplayer_authority():
			queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or (typeof(data[0])) != TYPE_NODE_PATH	# Target node path
	):
		push_error("Malformed bullet data.")
		return
	
	var vector: Vector2 = get_node(data[0]).global_position - global_position
	_startpoint = global_position
	_target_position = global_position + (vector / 2.0)
	_target_scale = vector.length()
	_scale_percentage_rate = speed / _target_scale
	rotation = vector.angle()
	
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		_modify_collider_to_harm_players()
	
	# Disable process and collision signals for non-owners.
	if not is_multiplayer_authority():
		set_physics_process(false)
