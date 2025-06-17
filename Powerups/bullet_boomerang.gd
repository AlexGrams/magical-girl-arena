class_name  BulletBoomerang
extends Bullet
## NOTE: Not implemented for use by enemies.


## How close the Boomerang needs to get to its destination before switching directions.
const touching_distance_threshold: float = 30.0

## Target enemy must be within this range
@export var max_range: float = 750

@onready var _squared_touching_distance_threshold: float = touching_distance_threshold ** 2
## The bullet object is replicated on all clients.
## This owner is the client's replicated version of the character that owns this bullet.
var _boomerang_owner: Node2D = null
## This boomerang's controller bullet.
var _controller: BulletBoomerangController = null
## Object that this boomerang is moving towards.
var _target: Node
## True if this boomerang is not idling at the player.
var _active: bool = true


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if (_boomerang_owner == null or _boomerang_owner.is_queued_for_deletion()):
		return
	
	if _target == null or _target.is_queued_for_deletion():
		# Target is no longer valid
		_target = _boomerang_owner
	else:
		# Move, then see if we're close enough to our target.
		global_position += (_target.global_position - global_position).normalized() * speed * delta
		if _target.global_position.distance_squared_to(global_position) <= _squared_touching_distance_threshold:
			if _target == _boomerang_owner:
				# We have returned back to our owner.
				if _active:
					_controller.add_ready_boomerang(self)
				_active = false
				_target = null
			else:
				# We have hit the object that we were aiming at, so return back to the owner.
				_target = _boomerang_owner


## Sets this boomerang's target to the farthest Enemy within range.
## Returns true if the target has been set to an Enemy.
func find_new_target() -> bool:
	var enemies: Array[Node] = []
	
	if _is_owned_by_player:
		enemies = get_tree().get_nodes_in_group("enemy")
	else:
		enemies = get_tree().get_nodes_in_group("player")
		
	if !enemies.is_empty():
		var farthest_distance = 0
		for enemy in enemies:
			var distance = global_position.distance_squared_to(enemy.global_position)
			if distance > farthest_distance and distance <= (max_range * max_range):
				_target = enemy
				_active = true
				farthest_distance = distance
	
	return _target != null and _target is Enemy


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning character 
		or typeof(data[1]) != TYPE_NODE_PATH	# Boomerang controller path
	):
		return
	
	_boomerang_owner = get_tree().root.get_node(data[0])
	_controller = get_tree().root.get_node(data[1])
	_target = _boomerang_owner
	
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		# When the player levels up this powerup, notify all clients about the level up.
		var boomerang_powerup := _boomerang_owner.get_node_or_null("BoomerangPowerup")
		# The Powerup child is not replicated, so only the client which owns this character has it.
		if boomerang_powerup != null:
			boomerang_powerup.powerup_level_up.connect(func(new_level: int, new_damage: float):
				level_up.rpc(new_level, new_damage)
			)
	
		# When the owner goes down, destroy this bullet
		_boomerang_owner.died.connect(func():
			queue_free()
		)
	else:
		_modify_collider_to_harm_players()
		
		# Destroy bullet when owning Enemy dies
		if is_multiplayer_authority():
			_boomerang_owner.died.connect(func(_enemy: Enemy):
				queue_free()
			)


func set_damage(damage:float):
	$Area2D.damage = damage


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(new_level: int, new_damage: float):
	$Area2D.damage = new_damage
	if new_level == 3:
		# Increase size
		scale = scale * 2
