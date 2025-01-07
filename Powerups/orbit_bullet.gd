extends Bullet

@export var radius = 2


func set_damage(damage:float):
	$BulletOffset/Area2D.damage = damage


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	rotate(speed * delta)


# Set up other properties for this bullet
func setup_bullet(_data: Array) -> void:
	$BulletOffset.position.y = radius
	# TODO: This function is called on the client and the server, but the "died" signal
	# Is only called once on the client. Why does it error then?
	
	# This bullet is parented to the player and destroys itself when the player dies.
	$"..".died.connect(func():
		print(get_multiplayer_authority())
		if is_multiplayer_authority():
			queue_free()
		else:
			destroy_orbit_bullet.rpc_id(1)
	)


# Must be done through RPC because clients run functionality to spawn the bullet, but bullets'
# authority is the server.
@rpc("any_peer", "call_remote")
func destroy_orbit_bullet() -> void:
	queue_free()
