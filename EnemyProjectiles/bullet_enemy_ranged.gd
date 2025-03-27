extends Bullet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += direction * speed * delta
	
	if is_multiplayer_authority():
		death_timer += delta
		if death_timer >= lifetime:
			queue_free()


# Try to free this bullet remotely. Call from any client when their own character touches 
# this bullet.
@rpc("any_peer", "call_local")
func request_delete() -> void:
	queue_free()


func set_damage(damage:float):
	$Area2D.damage = damage
