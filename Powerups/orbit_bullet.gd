extends Bullet

@export var radius = 2
var owning_player: Node2D = null


func set_damage(damage: float):
	$BulletOffset/Area2D.damage = damage


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if owning_player == null or owning_player.is_queued_for_deletion():
		return
	
	global_position = owning_player.global_position
	rotate(speed * delta)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or (typeof(data[0]) != TYPE_INT				# Owning ID
			and typeof(data[0]) != TYPE_NODE_PATH)	# Owning enemy
	):
		return
	
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
	
	var orbit_powerup := owning_player.get_node_or_null("OrbitPowerup")
	# The Powerup child is not replicated, so only the client which owns this character has it.
	if orbit_powerup != null:
		orbit_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				level_up.rpc(new_level, new_damage)
		)
		orbit_powerup.add_bullet(self)


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	$BulletOffset/Area2D.damage = new_damage



## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	sprite.self_modulate.a = GameState.other_players_bullet_opacity
	$BulletOffset/Sprite2D/Rainbow.self_modulate.a = GameState.other_players_bullet_opacity


# Must be done through RPC because clients run functionality to spawn the bullet, but bullets'
# authority is the server.
@rpc("any_peer", "call_remote")
func destroy_orbit_bullet() -> void:
	queue_free()
