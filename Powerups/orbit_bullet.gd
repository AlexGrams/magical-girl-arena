extends Bullet

@export var radius = 2
var owning_player: PlayerCharacterBody2D = null


func set_damage(damage: float):
	print(str(damage))
	$BulletOffset/Area2D.damage = damage


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	global_position = owning_player.global_position
	rotate(speed * delta)


# Set up other properties for this bullet
func setup_bullet(data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_INT		# Owning ID
	):
		return
		
	owning_player = GameState.player_characters.get(data[0])
	
	if owning_player == null:
		push_error("Orbit bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	
	$BulletOffset.position.y = radius
	var orbit_powerup := owning_player.get_node_or_null("OrbitPowerup")
	# The Powerup child is not replicated, so only the client which owns this character has it.
	if orbit_powerup != null:
		orbit_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				set_damage(new_damage)
		)
	
	# This bullet destroys itself when the player dies.
	if is_multiplayer_authority():
		owning_player.died.connect(func():
			queue_free()
		)


# Must be done through RPC because clients run functionality to spawn the bullet, but bullets'
# authority is the server.
@rpc("any_peer", "call_remote")
func destroy_orbit_bullet() -> void:
	queue_free()
