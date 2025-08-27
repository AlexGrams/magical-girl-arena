class_name BulletBall
extends Bullet


## Ball is not considered to be moving if its squared speed is less than this value.
const MOVING_THRESHOLD_SQUARED: float = 1.0

## Impulse applied to the ball when it touches a player.
@export var _kick_impulse: float = 10000.0
## Torque impule applied to the ball when it is kicked.
@export var _kick_torque: float = 900.0
## Number of enemies the ball can defeat before exploding and returning to normal size.
@export var _max_kills: int = 10
## How much the bigger the ball gets with each kill.
@export var _scale_increment: float = 1.0
## How much the mass of the Ball increases with each kill in kg.
@export var _mass_increment: float = 0.05
@export var _rigidbody: RigidBody2D = null
@export var _sprite_holder: Node2D = null
@export var _kick_area: Area2D = null
@export var _physics_collision_shape: CollisionShape2D

@onready var _scale_increment_vector: Vector2 = Vector2.ONE * _scale_increment
@onready var _original_mass: float = _rigidbody.mass
var _kills: int = 0
var _owning_player: PlayerCharacterBody2D = null
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0


func set_damage(damage: float, is_crit: bool = false):
	collider.damage = damage
	collider.is_crit = is_crit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
		collider.area_entered.disconnect(_on_bullet_hitbox_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning player
	):
		push_error("Malformed data array")
		return
	
	_owning_player = get_node(data[0])
	_is_owned_by_player = is_owned_by_player
	
	if _owning_player != null and is_multiplayer_authority():
		_owning_player.died.connect(func():
			queue_free()
		)
	
	# The Powerup child is not replicated, so only the client which owns this character has it.
	var ball_powerup: PowerupBall = _owning_player.get_node_or_null("PowerupBall")
	if ball_powerup != null:
		ball_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				_level_up.rpc(new_level, new_damage)
		)
		
		# Update crit values
		ball_powerup.crit_changed.connect(
			func(crit_chance: float, crit_multiplier: float):
				_crit_chance = crit_chance
				_crit_multiplier = crit_multiplier
		)


## This bullet's owner has leveled up its corresponding powerup.
@rpc("any_peer", "call_local")
func _level_up(_new_level: int, new_damage: float):
	collider.damage = new_damage


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass


func _on_player_kick_area_2d_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if other is PlayerCharacterBody2D:
		# Kick the ball by applying force and torque. Torque is only for visuals.
		var kick_direction: Vector2 = (global_position - other.global_position).normalized()
		_rigidbody.apply_force(kick_direction * _kick_impulse)
		
		if kick_direction.x > 0:
			_rigidbody.apply_torque_impulse(_kick_torque)
		else:
			_rigidbody.apply_torque_impulse(-_kick_torque)


## Damage hit Enemies. Only called on server.
func _on_bullet_hitbox_entered(area: Area2D) -> void:
	# Can only deal damage while moving.
	if _rigidbody.linear_velocity.length_squared() < MOVING_THRESHOLD_SQUARED:
		return
	
	var other: Node2D = area.get_parent()
	if other is Enemy:
		if other.health - collider.damage <= 0:
			# The Ball probably just got a kill, so increase its size.
			_kills += 1
			
			if _kills >= _max_kills:
				_sprite_holder.scale = Vector2.ONE
				collider.scale = Vector2.ONE
				_kick_area.scale = Vector2.ONE
				_physics_collision_shape.scale = Vector2.ONE
				_rigidbody.mass = _original_mass
				_kills = 0
			else:
				_sprite_holder.scale += _scale_increment_vector
				collider.scale += _scale_increment_vector
				_kick_area.scale += _scale_increment_vector
				_physics_collision_shape.scale += _scale_increment_vector
				_rigidbody.mass += _mass_increment
		other.take_damage(collider.damage)
