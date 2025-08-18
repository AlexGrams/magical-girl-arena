extends Bullet

## How far the center of the hitbox is from the character
@export var radius: float = 50
## Rotation in degrees that the scythe moves through in one sweep. 360 is a full rotation around the character.
@export var arc_length: float = 120
## Collision area that deals damage
@export var area: Area2D

var _owning_player: Node2D = null
var _half_lifetime: float = 0.0
var _signature_behavior: bool = true


func set_damage(damage: float, is_crit: bool = false):
	area.damage = damage
	area.is_crit = is_crit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.SCYTHE)
	_half_lifetime = lifetime / 2.0
	if not _signature_behavior:
		# Normal behavior: 
		# Calculate the speed in radians per second that the scythe moves in order to complete two swipes
		# in its lifetime.
		speed = ((arc_length * PI) / 180.0) * 2 / lifetime
	else:
		# Signature behavior:
		# Speed needed to complete three swipes
		speed = ((arc_length * PI) / 180.0) * 3 / lifetime
		$BulletOffset.scale = Vector2(1.5, 1.5)


func _process(delta: float) -> void:
	if _owning_player != null:
		global_position = _owning_player.global_position

	if not _signature_behavior:
		# Move in an arc
		if death_timer < _half_lifetime:
			rotate(speed * delta)
			$BulletOffset/ScytheSprite.flip_h = false
		else:
			rotate(-speed * delta)
			$BulletOffset/ScytheSprite.flip_h = true
	else:
		# Max level behavior: Move in an arc three times
		if death_timer > lifetime * 0.666:
			rotate(speed * delta)
			$BulletOffset/ScytheSprite.flip_h = false
		elif death_timer > lifetime * 0.333:
			rotate(-speed * delta)
			$BulletOffset/ScytheSprite.flip_h = true
		else:
			rotate(speed * delta)
			$BulletOffset/ScytheSprite.flip_h = false
	
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
