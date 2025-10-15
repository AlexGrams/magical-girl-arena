extends Bullet
## A persistent bullet which changes its transform to make it appear like the player is shooting
## a laser from their body that hits the nearest target.
## Since the server has authority over all bullets, each player with a laser needs to RPC the 
## server each frame to notify it of where that player's mouse is. The server uses the mouse
## position to set the transform of the laser.

@export var _area: Area2D = null
# Contains the visuals and collision for the laser
@export var _laser: Node2D = null

var _max_range: float = 0.0
var _owning_character: Node2D = null
## Only non-null on powerup owner's client.
var _powerup_laser: PowerupLaser = null
var _pointer_location: Vector2
var _piercing_active: bool = false
var _starting_position: Node2D = null
var _crit_chance: float = 0.0
var _crit_multiplier: float = 2.0


@rpc("any_peer", "call_local")
func _set_critical(new_crit_chance: float, new_crit_multiplier: float):
	_crit_chance = new_crit_chance
	_crit_multiplier = new_crit_multiplier


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This is intentionally blank. It overrides Bullet's _ready() function.
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# This is intentionally blank. It overrides Bullet's _process() function.
	pass


@rpc("any_peer", "call_local")
func set_pointer_direction(val: Vector2) -> void:
	_pointer_location = val


@rpc("any_peer", "call_local")
func _set_piercing(val: bool) -> void:
	_piercing_active = val


## Wrapper for set_pointer_direction that can be bound and unbound from signals.
func _call_set_pointer_direction(val: Vector2) -> void:
	set_pointer_direction.rpc(val)


func _physics_process(_delta: float) -> void:
	if _owning_character == null:
		return
	
	global_position = _starting_position.global_position
	
	var space_state = get_world_2d().direct_space_state
	var end_point: Vector2 = _starting_position.global_position + (_pointer_location - _starting_position.global_position).normalized() * _max_range
	var query := PhysicsRayQueryParameters2D.create(
		_starting_position.global_position, 
		end_point
	)
	query.collide_with_areas = true
	query.collision_mask = collider.collision_mask
	var result = space_state.intersect_ray(query)
	
	# Position and scale the laser beam
	if result and _is_owned_by_player:
		# The laser hit something and shouldn't be its full length.
		var crit: bool = randf() < _crit_chance
		var total_damage: float = _area.damage * (1.0 if not crit else _crit_multiplier)
		$AudioStreamPlayer2D.pitch_scale = 0.8
		$AudioStreamPlayer2D.volume_db = -25
		
		if not _piercing_active:
			# Non-signature functionality: Only harm the first enemy hit.
			end_point = result["position"]
			$HitmarkerSprite.global_position = end_point
			$HitmarkerSprite.show()
			
			var hit_node: Node2D = result["collider"].get_parent()
			if hit_node is Enemy or hit_node is DestructibleNode2D:
				hit_node.take_damage(total_damage, collider)
				if multiplayer.get_unique_id() == _area.owner_id:
					_powerup_laser.energy_did_damage()
					Analytics.add_powerup_damage(total_damage, _area.powerup_index)
		else:
			# Signature functionality: Harm all enemies the laser is touching
			var damage_done: float = 0
			for hit_area: Area2D in _area.get_overlapping_areas():
				var hit_node = hit_area.get_parent()
				if hit_node is Enemy or hit_node is DestructibleNode2D:
					hit_node.take_damage(total_damage, collider)
					damage_done += total_damage
			if multiplayer.get_unique_id() == _area.owner_id and damage_done > 0:
				_powerup_laser.energy_did_damage()
				Analytics.add_powerup_damage.rpc_id(_area.owner_id, damage_done, _area.powerup_index)
	else:
		# Play passive humming
		$AudioStreamPlayer2D.pitch_scale = 0.9
		$AudioStreamPlayer2D.volume_db = -30
		$HitmarkerSprite.hide()
		
	var hit_vector := end_point - _starting_position.global_position
	_laser.global_position = hit_vector / 2.0 + _starting_position.global_position
	_laser.rotation = hit_vector.angle()
	_laser.scale.x = hit_vector.length()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 6
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning Node2D
		or typeof(data[1]) != TYPE_FLOAT		# Range
		or typeof(data[2]) != TYPE_NODE_PATH	# Starting position
		or typeof(data[3]) != TYPE_BOOL			# If piercing is active
		or typeof(data[4]) != TYPE_FLOAT		# Crit chance
		or typeof(data[5]) != TYPE_FLOAT		# Crit multiplier
	):
		push_error("Malformed setup array")
		return
	
	_starting_position = get_node(data[2])
	_crit_chance = data[4]
	_crit_multiplier = data[5]
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		_owning_character = get_node(data[0])
	else:
		_modify_collider_to_harm_players()
		_owning_character = get_node_or_null(data[0])
		
		if is_multiplayer_authority():
			_owning_character.died.connect(func(_enemy: Enemy):
				queue_free()
			)
	
	if _owning_character == null:
		push_error("Laser bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	
	# The Powerup child is not replicated, so only the client which owns this character has it.
	_powerup_laser = _owning_character.get_node_or_null("PowerupLaser")
	if _powerup_laser != null:
		# Level up
		_powerup_laser.powerup_level_up.connect(
			func(new_level, new_damage):
				level_up.rpc(new_level, new_damage)
		)
		
		# Each frame, need to send the local player's mouse position to the server.
		# This signal is disconnected when the player goes down so that we aren't RPCing from a freed node.
		_powerup_laser.update_pointer_location.connect(_call_set_pointer_direction)
		_owning_character.died.connect(
			func():
				_powerup_laser.update_pointer_location.disconnect(_call_set_pointer_direction)
		)
		
		# Turn on signature functionality.
		_powerup_laser.activate_piercing.connect(
			func():
				_set_piercing.rpc(true)
		)
		
		# Update crit values
		_powerup_laser.crit_changed.connect(
			func(new_crit_chance: float, new_crit_multiplier: float):
				_set_critical.rpc_id(1, new_crit_chance, new_crit_multiplier)
		)
		
		# Deactivate
		_powerup_laser.deactivate.connect(
			func():
				_destroy.rpc_id(1)
		)
	
	_max_range = data[1]



## Only call on server.
@rpc("any_peer", "call_local", "reliable")
func _destroy() -> void:
	queue_free()


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	_area.damage = new_damage


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	# Laser's passive animation dictates its opacity.
	pass
