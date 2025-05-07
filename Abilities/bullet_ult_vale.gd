class_name BulletUltVale
extends Bullet
## Moves in variety of sinusoidal patterns before exploding at its destination.

const MOVEMENT_PATTERNS: int = 2

## Used to deal damage when the missile explodes, which is different from when it collides with something.
@export var _explosion_area: BulletHitbox = null

var _timer: float = 0.0
var _starting_direction: Vector2 = Vector2.ZERO
var _starting_rotation: float = 0.0
## Approximatly how far the missile will travel before exploding
var _distance: float = 0.0
## Amplitude factor of the missile's movement pattern.
var _amplitude: float = 1.0
## Frequency factor of the missile's movement pattern.
var _frequency: float = 1.0


## Special functionality: only sets the explosion damage.
func set_damage(damage: float):
	_explosion_area.damage = damage


func _ready() -> void:
	_starting_direction = direction
	_starting_rotation = Vector2.LEFT.angle_to(direction)
	## TODO: Set in setup_bullet
	_distance = randf_range(250.0, 750.0)
	lifetime = _distance / speed
	
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.REVOLVING)


func _process(delta: float) -> void:
	#global_position += direction * speed * delta
	death_timer += delta
	
	# For testing, 2PI is a complete cycle.
	_timer += (delta / lifetime) * 2 * PI
	direction = Vector2(1.0, _amplitude * cos(_frequency * _timer)).normalized().rotated(_starting_rotation)
	global_position += direction * speed * delta
	
	# TODO: Somehow the rotation equation is off.
	#rotation_degrees = rad_to_deg(Vector2.UP.angle_to(direction))
	
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	# TODO: Probably don't want to do anything here. Not really intending for this to be used by Enemies.
	if not is_multiplayer_authority():
		return
	
	if _is_owned_by_player:
		# Player's bullets should be destroyed when they hit something if applicable.
		if destroy_on_hit:
			queue_free()
	else:
		# Enemy's bullets should deal damage if they hit a player's bullet.
		# NOTE: Enemy bullets are deleted when the character that they hit calls an RPC to delete them.
		if area is BulletHitbox:
			take_damage(area.damage)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 3
		or (typeof(data[0])) != TYPE_FLOAT		# Collision damage
		or (typeof(data[1])) != TYPE_FLOAT		# Explosion damage
		or (typeof(data[2])) != TYPE_INT		# Movement mode
	):
		push_error("Malformed setup_bullet data argument.")
		return
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		_is_owned_by_player = false
		_health = max_health
		_modify_collider_to_harm_players()
	
	collider.damage = data[0]
	_explosion_area.damage = data[1]
	
	# Determine movement mode
	match(data[2]):
		0:
			# One cycle
			_amplitude = 1.0
			_frequency = 1.0
		1:
			# Four cycles
			_amplitude = 1.0
			_frequency = 4.0
		_:
			push_error("Movement mode not defined.")
