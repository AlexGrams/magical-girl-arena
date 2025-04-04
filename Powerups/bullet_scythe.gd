extends Bullet

## How far the center of the hitbox is from the character
@export var radius: float = 100
## Rotation in degrees that the scythe moves through in one sweep. 360 is a full rotation around the character.
@export var arc_length: float = 120

var _owning_player: Node2D = null
var _half_lifetime: float = 0.0
var _signature_behavior: bool = false


func set_damage(damage: float):
	$BulletOffset/Area2D.damage = damage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not _signature_behavior:
		# Normal behavior: 
		# Calculate the speed in radians per second that the scythe moves in order to complete two swipes
		# in its lifetime.
		speed = ((arc_length * PI) / 180.0) * 2 / lifetime
		_half_lifetime = lifetime / 2.0
	else:
		# Signature behavior: Set up to rotate in a complete circle over lifetime
		speed = 2 * PI / lifetime


func _process(delta: float) -> void:
	if _owning_player != null:
		global_position = _owning_player.global_position
	
	if not _signature_behavior:
		# Move in an arc
		if death_timer < _half_lifetime:
			rotate(speed * delta)
		else:
			rotate(-speed * delta)
	else:
		# Max level behavior: Spin around in a complete circle
		rotate(speed * delta)
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (data.size() > 2
		or (data.size() == 2						# Owned by player
			and (typeof(data[0]) != TYPE_INT		# Owning player ID
				 or typeof(data[1]) != TYPE_BOOL	# Is signature behavior active
			)
		)
		or (data.size() == 1						# Owned by enemy
			and typeof(data[0]) != TYPE_NODE_PATH	# Path to owning node
		)
	):
		push_error("Malformed bullet setup data Array.")
		return
	
	if is_owned_by_player:
		# Player bullet
		_owning_player = GameState.player_characters.get(data[0])
		_signature_behavior = data[1]
	else:
		# Enemy bullet
		_owning_player = get_node_or_null(data[0])
		_modify_collider_to_harm_players()
	
	if _owning_player == null:
		push_error("Scythe bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	global_position = _owning_player.global_position
	
	$BulletOffset.position.y = radius
	# Make it so that the angle of the starting direction is the midpoint of the scythe sweeps.
	rotation = direction.angle() - PI / 2 - (((arc_length * PI) / 180.0) / 2)
