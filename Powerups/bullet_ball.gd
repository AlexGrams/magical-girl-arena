class_name BulletBall
extends Bullet


## Impulse applied to the ball when it touches a player.
@export var _kick_impulse: float = 10000.0
## Torque impule applied to the ball when it is kicked.
@export var _kick_torque: float = 900.0
@export var _rigidbody: RigidBody2D = null

var _owning_player: PlayerCharacterBody2D = null
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)


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
		var direction: Vector2 = (global_position - other.global_position).normalized()
		_rigidbody.apply_force(direction * _kick_impulse)
		
		if direction.x > 0:
			_rigidbody.apply_torque_impulse(_kick_torque)
		else:
			_rigidbody.apply_torque_impulse(-_kick_torque)
		print("KICK")
		
			
		#for i: int in range(get_slide_collision_count()):
			#var collision: KinematicCollision2D = get_slide_collision(i)
			#var collider: Object = collision.get_collider()
			#var colliding_object: Node = collider.get_parent()
			#if collider is RigidBody2D and collider is BulletBall:
				#print("Kick")
				#collider.apply_force(collision.get_normal() * -300.0)
