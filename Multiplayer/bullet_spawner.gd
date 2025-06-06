class_name BulletSpawner
extends MultiplayerSpawner


func _init():
	spawn_function = _spawn_bullet


# Spawns a bullet replicated for all clients. Returns the new bullet.
func _spawn_bullet(data):
	if (
		data.size() != 8
		or typeof(data[0]) != TYPE_STRING	# Path to bullet scene or bullet scene UID
		or typeof(data[1]) != TYPE_VECTOR2	# Position
		or typeof(data[2]) != TYPE_VECTOR2	# Direction
		or typeof(data[3]) != TYPE_FLOAT	# Damage
		or typeof(data[4]) != TYPE_BOOL		# Is owned by player
		or typeof(data[5]) != TYPE_INT		# Owning player ID, if any
		or typeof(data[6]) != TYPE_INT		# Powerup index, if owned by player
		or typeof(data[7]) != TYPE_ARRAY	# Bullet setup parameters
	):
		push_error("Bullet could not be instantiated because of malformed 'data' parameter.")
		return null
	
	var bullet: Bullet = load(data[0]).instantiate()
	if bullet == null:
		push_error("Bullet could not be instantiated from path: " + str(data[0]))
	
	bullet.position = data[1]
	bullet.direction = data[2]
	bullet.set_damage(data[3])
	
	# Call the setup function on the bullet once it is added to the scene, but only once.
	bullet.tree_entered.connect(func():
		bullet.setup_bullet(data[4], data[7])
		if data[5] > 0 and data[6] > -1:
			bullet.setup_analytics(data[5], data[6])
	, CONNECT_ONE_SHOT)
	
	return bullet


# Spawn a bullet. Should only be called on the server with rpc_id(1, data).
@rpc("any_peer", "call_local")
func request_spawn_bullet(data) -> void:
	self.spawn(data)
