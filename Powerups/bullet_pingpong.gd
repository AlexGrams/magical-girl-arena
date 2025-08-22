class_name BulletPingPong
extends Bullet
## PingPong aka Shuttle Shuffle bounces between all player characters.
##
## NOTE: Powerup does not currently work correctly if someone (such as the host) spawns in with the 
## pingpong before all the other characters have spawned in.


## How close the PingPong needs to get to its destination before switching directions.
const touching_distance_threshold: float = 30.0

## Target enemy must be within this range
@export var max_range: float = 750
## How much the damage increases per second since the last bounce, expressed as a fraction.
@export var _damage_percent_increase_per_second: float = 0.25
## How much temp HP is granted to allies.
@export var _shield_amount: int = 10
## Minimum time in seconds that the bullets needs to be traveling for in order to grant temp HP.
@export var _min_travel_time_for_shield: float = 1.0
## Minimum time in seconds that temp HP granted by this powerup will last for.
@export var _min_shield_duration: float = 0.5
## Determines how travel time over _min_travel_time_for_shield is converted to temp HP duration.
## A value of 1 means that for each second long than the minimum time the bullet travels, one second
## is added to the temp HP duration.
@export var _shield_duration_per_second_traveled_over_threshold: float = 1.0

@onready var _squared_touching_distance_threshold: float = touching_distance_threshold ** 2
## The bullet object is replicated on all clients.
## This owner is the client's replicated version of the character that owns this bullet.
var _pingpong_owner: Node2D = null
## Which node the pingpong is currently moving towards.
var _target: Node2D = null
## List of nodes that the pingpong can bounce between.
var _all_targets: Array[Node2D] = []
## index of _all_targets that the pingpong is currently moving towards.
var _target_index: int = 0
## How long the bullet has been moving for since it last reached a target
var _travel_time: float = 0.0
## How much damage the shuttle does without travel time.
var _base_damage: float = 0.0
## How much damage increases per second of travel time.
var _damage_increase_per_second: float = 0.0
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0


@rpc("any_peer", "call_local")
func _set_critical(new_crit_chance: float, new_crit_multiplier: float):
	_crit_chance = new_crit_chance
	_crit_multiplier = new_crit_multiplier


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not _is_owned_by_player:
		push_error("PingPong not configured for use by Enemies.")
		return
	
	if (
			_pingpong_owner == null
			or _pingpong_owner.is_queued_for_deletion()
			or len(_all_targets) <= 0
	):
		return
	
	global_position += (_target.global_position - global_position).normalized() * speed * delta
	_travel_time += delta
	
	# Choose the next target if we are close enough to our current target.
	if global_position.distance_squared_to(_target.global_position) <= _squared_touching_distance_threshold:
		# Grant shield
		if _travel_time > _min_travel_time_for_shield:
			_target.add_temp_health(
				_shield_amount, 
				_min_shield_duration + (_travel_time - _min_travel_time_for_shield) * _shield_duration_per_second_traveled_over_threshold
			)
			
			# The exact position of the pingpong becomes desynced over time, so occasionally
			# RPC to synchronize the position.
			if is_multiplayer_authority() and _target_index == 0:
				_teleport.rpc(global_position)
		
		_target_index = (_target_index + 1) % len(_all_targets)
		_target = _all_targets[_target_index]
		_travel_time = 0.0
	
	# Scale damage based off of time since last bounce.
	if is_multiplayer_authority():
		collider.damage = _base_damage + _travel_time * _damage_increase_per_second
		
		# Account for critical
		collider.is_crit = randf() < _crit_chance
		if collider.is_crit:
			collider.damage *= _crit_multiplier


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning character 
	):
		return
	
	_pingpong_owner = get_tree().root.get_node(data[0])
	global_position = _pingpong_owner.global_position
	
	# The authority over this bullet sets the order by which the pingpong bounces between targets.
	if is_multiplayer_authority():
		_all_targets.assign(GameState.player_characters.values())
		_target_index = 0
		_target = _all_targets[_target_index]
	else:
		# If we are the client, we need to request from the server the order in which to visit targets.
		# This is done using two RPCs, which will complete this frame.
		request_all_targets.rpc_id(1)
	
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		# When the player levels up this powerup, notify all clients about the level up.
		var powerup_ping_pong: PowerupPingPong = _pingpong_owner.get_node_or_null("PowerupPingPong")
		# The Powerup child is not replicated, so only the client which owns this character has it.
		if powerup_ping_pong != null:
			powerup_ping_pong.add_bullet(self)
			
			# Level up
			powerup_ping_pong.powerup_level_up.connect(func(new_level: int, new_damage: float):
				level_up.rpc(new_level, new_damage)
			)
			
			# Crit update
			_set_critical.rpc_id(1, powerup_ping_pong.crit_chance, powerup_ping_pong.crit_multiplier)
			powerup_ping_pong.crit_changed.connect(
				func(new_crit_chance: float, new_crit_multiplier: float):
					_set_critical.rpc_id(1, new_crit_chance, new_crit_multiplier)
			)
	
		# When the owner goes down, destroy this bullet
		_pingpong_owner.died.connect(func():
			queue_free()
		)
	else:
		_modify_collider_to_harm_players()
		
		# Destroy bullet when owning Enemy dies
		if is_multiplayer_authority():
			_pingpong_owner.died.connect(func(_enemy: Enemy):
				queue_free()
			)


func set_damage(damage: float, _is_crit: bool = false):
	_base_damage = damage
	_damage_increase_per_second = _damage_percent_increase_per_second * damage


@rpc("authority", "call_remote")
func _teleport(new_position: Vector2) -> void:
	global_position = new_position


## Call from a client only to request the order in which targets are visited from the server.
@rpc("any_peer", "call_remote")
func request_all_targets() -> void:
	var node_paths: Array[NodePath]
	for node: Node2D in _all_targets:
		node_paths.append(node.get_path())
	set_all_targets.rpc_id(multiplayer.get_remote_sender_id(), node_paths, _target_index, global_position)


## Gives a client the order in which this PingPong will bounce between targets.
@rpc("authority", "call_local")
func set_all_targets(targets: Array[NodePath], current_index: int, current_position: Vector2) -> void:
	_all_targets.clear()
	for path: NodePath in targets:
		_all_targets.append(get_tree().root.get_node(path))
	_target_index = current_index
	_target = _all_targets[_target_index]
	global_position = current_position


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(new_level: int, new_damage: float):
	_base_damage = new_damage
	_damage_increase_per_second = _damage_percent_increase_per_second * new_damage
	if new_level == 3:
		# Increase size
		scale = scale * 2


@rpc("any_peer", "call_local")
func boost() -> void:
	speed *= 2.0


@rpc("any_peer", "call_local")
func unboost() -> void:
	speed /= 2.0


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass
