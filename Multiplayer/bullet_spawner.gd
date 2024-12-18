class_name BulletSpawner
extends MultiplayerSpawner


func _init():
	spawn_function = _spawn_bullet


# Spawns a bullet replicated for all clients. Returns the new bullet.
func _spawn_bullet(data):
	if (
		data.size() != 4
		or typeof(data[0]) != TYPE_STRING	# Path to bullet scene
		or typeof(data[1]) != TYPE_VECTOR2	# Position
		or typeof(data[2]) != TYPE_VECTOR2	# Direction
		or typeof(data[3]) != TYPE_FLOAT	# Damage
	):
		return null
	
	var bullet = load(data[0]).instantiate()
	bullet.position = data[1]
	bullet.direction = data[2]
	bullet.set_damage(data[3])
	#get_tree().root.get_node("Playground").add_child(bullet, true)
	
	return bullet


# Spawn a bullet. Should only be called on the server with rpc_id(1, data).
@rpc("any_peer", "call_local")
func request_spawn_bullet(data):
	self.spawn(data)
