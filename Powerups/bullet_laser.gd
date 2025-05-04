extends Bullet
## A persistent bullet which changes its transform to make it appear like the player is shooting
## a laser from their body that hits the nearest target.
## Since the server has authority over all bullets, each player with a laser needs to RPC the 
## server each frame to notify it of where that player's mouse is. The server uses the mouse
## position to set the transform of the laser, and the MultiplayerSynchronizer makes sure the
## new transform is replicated across all clients.

@export var _area: Area2D = null

var _max_range: float = 0.0
var _owning_character: Node2D = null
var _pointer_location: Vector2
var _signature_active: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


@rpc("any_peer", "call_local")
func set_pointer_direction(val: Vector2) -> void:
	_pointer_location = val


func _physics_process(_delta: float) -> void:
	if _owning_character == null:
		return
	
	var space_state = get_world_2d().direct_space_state
	var end_point: Vector2 = _owning_character.global_position + (_pointer_location - _owning_character.global_position).normalized() * _max_range
	var query := PhysicsRayQueryParameters2D.create(
		_owning_character.global_position, 
		end_point
	)
	query.collide_with_areas = true
	query.collision_mask = collider.collision_mask
	var result = space_state.intersect_ray(query)
	
	# Position and scale the laser beam
	if result and is_multiplayer_authority() and _is_owned_by_player:
		# The laser hit something and shouldn't be its full length.
		$AudioStreamPlayer2D.pitch_scale = 0.8
		$AudioStreamPlayer2D.volume_db = -25
		
		if not _signature_active:
			# Non-signature functionality: Only harm the first enemy hit.
			end_point = result["position"]
		
			var hit_node: Node2D = result["collider"].get_parent()
			if hit_node is Enemy:
				hit_node.take_damage($Area2D.damage)
		else:
			# Signature functionality: Harm all enemies the laser is touching
			for hit_area: Area2D in _area.get_overlapping_areas():
				if hit_area.get_parent() is Enemy:
					hit_area.get_parent().take_damage($Area2D.damage)
	else:
		# Play passive humming
		$AudioStreamPlayer2D.pitch_scale = 0.9
		$AudioStreamPlayer2D.volume_db = -30
		
	var hit_vector := end_point - _owning_character.global_position
	global_position = hit_vector / 2.0 + _owning_character.global_position
	rotation = hit_vector.angle()
	scale.x = hit_vector.length()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or (typeof(data[0])) != TYPE_NODE_PATH	# Owning Node2D
		or (typeof(data[1])) != TYPE_FLOAT		# Range
	):
		return
	
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		_owning_character = get_node(data[0])
	
		# This bullet destroys itself when the player dies.
		if is_multiplayer_authority():
			_owning_character.died.connect(func():
				queue_free()
			)
	else:
		_modify_collider_to_harm_players()
		_owning_character = get_node_or_null(data[0])
		
		if is_multiplayer_authority():
			_owning_character.died.connect(func(_enemy: Enemy):
				queue_free()
			)
	
	if _owning_character == null:
		push_error("Orbit bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	
	# The Powerup child is not replicated, so only the client which owns this character has it.
	var laser_powerup: PowerupLaser = _owning_character.get_node_or_null("PowerupLaser")
	if laser_powerup != null:
		laser_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				level_up.rpc(new_level, new_damage)
		)
		
		# Each frame, need to send the local player's mouse position to the server.
		laser_powerup.update_pointer_location.connect(
			func(new_pointer_location):
				set_pointer_direction.rpc(new_pointer_location)
		)
		
		# Turn on signature functionality.
		laser_powerup.activate_signature.connect(
			func():
				_signature_active = true
		)
	
	_max_range = data[1]


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	$Area2D.damage = new_damage
