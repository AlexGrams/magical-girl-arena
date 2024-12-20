class_name BulletSpawner
extends MultiplayerSpawner


func _init():
	spawn_function = _spawn_bullet


# Spawns a bullet replicated for all clients. Returns the new bullet.
func _spawn_bullet(data):
	if (
		data.size() != 6
		or typeof(data[0]) != TYPE_STRING	# Path to bullet scene
		or typeof(data[1]) != TYPE_VECTOR2	# Position
		or typeof(data[2]) != TYPE_VECTOR2	# Direction
		or typeof(data[3]) != TYPE_FLOAT	# Damage
		or (typeof(data[4]) != TYPE_SIGNAL	# Powerup level up signal
			and typeof(data[4]) != TYPE_NIL)
		or typeof(data[5]) != TYPE_ARRAY	# Bullet setup parameters
	):
		return null
	
	var bullet = load(data[0]).instantiate()
	bullet.position = data[1]
	bullet.direction = data[2]
	bullet.set_damage(data[3])
	#$"..".add_child(bullet, true)
	
	#if data[4] != null:
		#data[4].connect(bullet.level_up)
	
	bullet.tree_entered.connect(func():
		bullet.setup_bullet(data[5])
	)
	
	return bullet


# Spawn a bullet. Should only be called on the server with rpc_id(1, data).
@rpc("any_peer", "call_local")
func request_spawn_bullet(data) -> void:
	self.spawn(data)
