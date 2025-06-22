extends Bullet
## A persistent bullet which changes its transform to make it appear like the player is shooting
## a laser from their body that hits the nearest target.
## Since the server has authority over all bullets, each player with a laser needs to RPC the 
## server each frame to notify it of where that player's mouse is. The server uses the mouse
## position to set the transform of the laser.

@export var _area: Area2D = null
# Contains the visuals and collision for the laser
@export var _laser: Node2D = null
@export var _animation_player:AnimationPlayer = null

var _max_range: float = 0.0
## Squared max range for distance calculations
var _max_range_squared: float = 0.0
var _owning_character: Node2D = null
var _starting_position: Node2D = null
## Indicates if the tether is visually on or not
var _visual_is_active: bool = false


## Returns PlayerCharacterBody2D that is nearest to _owning_character if any exists.
func _get_nearest_player_position() -> Vector2: 
	var nearest: Node2D = _owning_character
	var least_distance: float = INF
	
	for player: Node2D in GameState.player_characters.values():
		if player != _owning_character:
			var dist: float = player.position.distance_squared_to(nearest.position)
			if dist < least_distance:
				least_distance = dist
				nearest = player
	
	return nearest.position


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This is intentionally blank. It overrides Bullet's _ready() function.
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# This is intentionally blank. It overrides Bullet's _process() function.
	pass


func _physics_process(_delta: float) -> void:
	if _owning_character == null:
		return
	
	var target_position: Vector2 = _get_nearest_player_position()
	var end_point: Vector2
	if _owning_character.position.distance_squared_to(target_position) <= _max_range_squared:
		# The Tether is active and connects to the nearest player.
		if not _visual_is_active:
			_animation_player.play("fade_in")
			_visual_is_active = true
			
		end_point = _starting_position.global_position + (target_position - _starting_position.global_position).normalized() * _max_range
	
		if is_multiplayer_authority():
			# Harm all enemies the Tether is touching.
			var damage_done: float = 0
			for hit_area: Area2D in _area.get_overlapping_areas():
				var hit_node = hit_area.get_parent()
				if hit_node is Enemy or hit_node is LootBox:
					hit_node.take_damage(_area.damage)
					damage_done += _area.damage
			Analytics.add_powerup_damage.rpc_id(_area.owner_id, damage_done, _area.powerup_index)
		
		$AudioStreamPlayer2D.pitch_scale = 0.8
		$AudioStreamPlayer2D.volume_db = -25
	else:
		# The Tether is deactivated since there isn't anyone else in range.
		if _visual_is_active:
			_animation_player.play("fade_out")
			await _animation_player.animation_finished
			end_point = _owning_character.position
			_visual_is_active = false
		else:
			end_point = _owning_character.position
		
		# Play passive humming
		$AudioStreamPlayer2D.pitch_scale = 0.9
		$AudioStreamPlayer2D.volume_db = -30
		$HitmarkerSprite.hide()
	
	# Position and scale the laser.
	if target_position.distance_squared_to(_starting_position.global_position) < _max_range_squared:
		end_point = target_position
	
	var hit_vector := end_point - _starting_position.global_position
	_laser.global_position = hit_vector / 2.0 + _starting_position.global_position
	_laser.rotation = hit_vector.angle()
	_laser.scale.x = hit_vector.length()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 4
		or (typeof(data[0])) != TYPE_NODE_PATH	# Owning Node2D
		or (typeof(data[1])) != TYPE_FLOAT		# Range
		or (typeof(data[2])) != TYPE_NODE_PATH  # Starting position
		or (typeof(data[3])) != TYPE_BOOL		# If piercing is active
	):
		return
	
	_starting_position = get_node(data[2])
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
		push_error("Laser bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	
	# The Powerup child is not replicated, so only the client which owns this character has it.
	var tether_powerup: PowerupTether = _owning_character.get_node_or_null("PowerupTether")
	if tether_powerup != null:
		tether_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				level_up.rpc(new_level, new_damage)
		)
	
	_max_range = data[1]
	_max_range_squared = _max_range ** 2


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	_area.damage = new_damage
