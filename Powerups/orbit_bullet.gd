class_name BulletOrbit
extends Bullet

@export var radius = 2

var owning_player: Node2D = null

var _base_damage: float = 0.0
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0


func set_damage(damage: float, is_crit: bool = false):
	_base_damage = damage
	collider.damage = damage
	collider.is_crit = is_crit


@rpc("any_peer", "call_local")
func _set_critical(new_crit_chance: float, new_crit_multiplier: float):
	_crit_chance = new_crit_chance
	_crit_multiplier = new_crit_multiplier


func _ready() -> void:
	if not is_multiplayer_authority():
		set_physics_process(false)


func _process(delta: float) -> void:
	if owning_player == null or owning_player.is_queued_for_deletion():
		return
	
	global_position = owning_player.global_position
	rotate(speed * delta)
	
	# Orbit powerup owned by enemy despawns after some time.
	if not _is_owned_by_player and is_multiplayer_authority():
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()


## Determines crit functionality using the server only.
func _physics_process(_delta: float) -> void:
	# Randomly determine if this bullet does crit damage this frame.
	if _crit_chance > 0.0:
		collider.is_crit = randf() < _crit_chance
		collider.damage = _base_damage * (1.0 if not collider.is_crit else _crit_multiplier)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or (typeof(data[0]) != TYPE_INT				# Owning ID
			and typeof(data[0]) != TYPE_NODE_PATH)	# Owning enemy
	):
		push_error("Malformed data array")
		return
	
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		owning_player = GameState.player_characters.get(data[0])
	
		# This bullet destroys itself when the player dies.
		if is_multiplayer_authority():
			owning_player.died.connect(func():
				queue_free()
			)
	else:
		_modify_collider_to_harm_players()
		owning_player = get_node_or_null(data[0])
		
		if is_multiplayer_authority():
			owning_player.died.connect(func(_enemy: Enemy):
				queue_free()
			)
	
	if owning_player == null:
		push_error("Orbit bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	
	$BulletOffset.position.y = radius
	rotate(direction.angle())
	
	var orbit_powerup: PowerupOrbit = owning_player.get_node_or_null("OrbitPowerup")
	# The Powerup child is not replicated, so only the client which owns this character has it.
	if orbit_powerup != null:
		# Level up
		orbit_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				level_up.rpc(new_level, new_damage)
		)
		
		# Crit updates
		_set_critical.rpc_id(1, orbit_powerup.crit_chance, orbit_powerup.crit_multiplier)
		orbit_powerup.crit_changed.connect(
			func(new_crit_chance: float, new_crit_multiplier: float):
				_set_critical.rpc_id(1, new_crit_chance, new_crit_multiplier)
		)
		
		orbit_powerup.add_bullet(self)


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	collider.damage = new_damage



## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	sprite.self_modulate.a = GameState.other_players_bullet_opacity
	$BulletOffset/Sprite2D/Rainbow.self_modulate.a = GameState.other_players_bullet_opacity


# Must be done through RPC because clients run functionality to spawn the bullet, but bullets'
# authority is the server.
@rpc("any_peer", "call_remote")
func destroy_orbit_bullet() -> void:
	queue_free()


@rpc("any_peer", "call_local")
func boost() -> void:
	speed *= 1.25


@rpc("any_peer", "call_local")
func unboost() -> void:
	speed /= 1.25
