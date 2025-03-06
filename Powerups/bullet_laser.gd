extends Bullet

var _max_range: float = 0.0
var _owning_character: Node2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	if (
		not is_multiplayer_authority()
		or _owning_character == null
	):
		return
	
	var space_state = get_world_2d().direct_space_state
	var end_point: Vector2 = _owning_character.global_position + (get_global_mouse_position() - _owning_character.global_position).normalized() * _max_range
	var query := PhysicsRayQueryParameters2D.create(
		_owning_character.global_position, 
		end_point
	)
	query.collide_with_areas = true
	query.collision_mask = collider.collision_mask
	var result = space_state.intersect_ray(query)
	
	# Position and scale the laser beam
	if result:
		# The laser hit something and shouldn't be its full length.
		end_point = result["position"]
		
		var hit_node: Node2D = result["collider"].get_parent()
	
	var hit_vector := end_point - _owning_character.global_position
	global_position = hit_vector / 2.0 + _owning_character.global_position
	rotation = hit_vector.angle()
	scale.x = hit_vector.length()
	
	# TODO: Only do damage if we hit something. See if we can damage the thing that we hit.
	# TODO: Make it hit enemies


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or (typeof(data[0])) != TYPE_NODE_PATH	# Owning Node2D
		or (typeof(data[1])) != TYPE_FLOAT		# Range
	):
		return
	
	if is_owned_by_player:
		_owning_character = get_node(data[0])#get_tree().get_node
	
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
	var orbit_powerup := _owning_character.get_node_or_null("OrbitPowerup")
	if orbit_powerup != null:
		orbit_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				level_up.rpc(new_level, new_damage)
		)
	
	_max_range = data[1]


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	$BulletOffset/Area2D.damage = new_damage
