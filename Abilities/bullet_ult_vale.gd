class_name BulletUltVale
extends Bullet
## Moves in variety of sinusoidal patterns before exploding at its destination.

const MOVEMENT_PATTERNS: int = 4

@onready var _explosion_vfx: PackedScene = preload("res://Sprites/Map/leaf_explosion.tscn")

## How long the explosion hitbox should linger before this bullet is destroyed.
@export var _explosion_lifetime: float = 0.05
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
var _explosion_collision_layer: int = 0
## Has the missile already exploded?
var _exploded: bool = false


## Special functionality: only sets the explosion damage.
func set_damage(damage: float):
	_explosion_area.damage = damage


func _ready() -> void:
	_explosion_collision_layer = _explosion_area.collision_layer
	_explosion_area.collision_layer = 0
	
	_starting_direction = direction
	_starting_rotation = Vector2.LEFT.angle_to(direction)
	lifetime = _distance / speed
	
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.REVOLVING)


func _process(delta: float) -> void:
	#global_position += direction * speed * delta
	death_timer += delta
	
	if death_timer < lifetime:
		# Move during the main part of the missile's lifetime.
		_timer += (delta / lifetime) * 2 * PI
		direction = Vector2(1.0, _amplitude * cos(_frequency * _timer)).normalized().rotated(_starting_rotation)
		global_position += direction * speed * delta
	elif not _exploded:
		# The missile has just exceded its travel lifetime, so blow up. 
		_explode()
	elif death_timer >= lifetime + _explosion_lifetime and is_multiplayer_authority():
		# The missile has exploded and lingered, so remove it.
		queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
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


## Causes damage in an area around the missile, then frees it.
func _explode() -> void:
	# Spawn particles
	var playground: Node2D = get_tree().root.get_node_or_null("Playground")
	if playground != null:
		var explosion_particles: GPUParticles2D = _explosion_vfx.instantiate()
		explosion_particles.global_position = global_position
		playground.add_child(explosion_particles)
	
	_exploded = true
	sprite.visible = false
	
	if not is_multiplayer_authority():
		return
	
	# Switch to only use the explosion collider.
	_explosion_area.collision_layer = _explosion_collision_layer
	collider.collision_layer = 0


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 4
		or (typeof(data[0])) != TYPE_FLOAT		# Collision damage
		or (typeof(data[1])) != TYPE_FLOAT		# Explosion damage
		or (typeof(data[2])) != TYPE_INT		# Movement mode
		or (typeof(data[3])) != TYPE_FLOAT		# Travel distance
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
		2: 
			# One cycle with higher, negative amplitude
			_amplitude = -2.0
			_frequency = 1.0
		3:
			# Two cycles, negative amplitude
			_amplitude = -1.0
			_frequency = 2.0
		_:
			push_error("Movement mode not defined.")
	
	# The distance the missile travels along the sine wave is different from the straight line distance
	# given as input. The input distance is scaled using the amplitude of the sine wave to approximate
	# the actual arc length distance. The exact calculation involves taking an integral, which is
	# to expensive for what we want to do here. Magic numbers were found by plugging the equation
	# for arc length of a sine wave into a calculator.
	_distance = data[3] * (1.2 + 0.6 * (abs(_amplitude) - 1))
