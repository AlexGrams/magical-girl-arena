extends Bullet

## How far the center of the hitbox is from the character
@export var radius: float = 100
## Rotation in degrees that the scythe moves through in one sweep. 360 is a full rotation around the character.
@export var arc_length: float = 120

var _owning_player: Node2D = null
var _half_lifetime: float = 0.0


func set_damage(damage: float):
	$BulletOffset/Area2D.damage = damage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Calculate the speed in radians per second that the scythe moves in order to complete two swipes
	# in its lifetime.
	speed = ((arc_length * PI) / 180.0) * 2 / lifetime
	_half_lifetime = lifetime / 2.0


func _process(delta: float) -> void:
	if _owning_player != null:
		global_position = _owning_player.global_position
	
	if death_timer < _half_lifetime:
		rotate(speed * delta)
	else:
		rotate(-speed * delta)
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


# Set up other properties for this bullet
func setup_bullet(data: Array) -> void:
	if (
		(data.size() != 1 and data.size() != 2)
		or (typeof(data[0]) != TYPE_INT				# Owning ID
			and typeof(data[0]) != TYPE_NODE_PATH)	# Path to owning node
													# Optional bool if it is a player bullet.
	):
		push_error("Malformed bullet setup data Array.")
		return
	
	if typeof(data[0]) == TYPE_INT:
		# Player bullet
		_owning_player = GameState.player_characters.get(data[0])
	else:
		# Enemy bullet
		_owning_player = get_node_or_null(data[0])
	
	if _owning_player == null:
		push_error("Scythe bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	global_position = _owning_player.global_position
	
	if data.size() >= 2 and not data[1]:
		# This bullet harms enemies by default, but can be modified to harm players instead.
		if collider != null:
			collider.collision_layer = 0
			collider.collision_mask = 0
			collider.set_collision_layer_value(Constants.ENEMY_BULLET_COLLISION_LAYER, true)
			collider.set_collision_mask_value(Constants.ENEMY_BULLET_COLLISION_MASK, true)
	
	$BulletOffset.position.y = radius
	# Make it so that the angle of the starting direction is the midpoint of the scythe sweeps.
	rotation = direction.angle() - PI / 2 - (((arc_length * PI) / 180.0) / 2)
