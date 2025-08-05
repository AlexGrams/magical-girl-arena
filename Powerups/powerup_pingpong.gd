extends Powerup


var bullet_scene := "res://Powerups/bullet_pingpong.tscn"

var _bullets: Array[BulletPingPong] = []


func add_bullet(new_bullet: BulletPingPong) -> void:
	_bullets.append(new_bullet)


func _ready():
	pass


func activate_powerup():
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[$"..".get_path()]
			]
		)
	else:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				-1,
				-1,
				[$"..".get_path()]
			]
		)


# Does nothing. The bullet destroys itself based off of the player's "died" signal.
func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	for bullet: BulletPingPong in _bullets:
		if bullet != null:
			bullet.boost.rpc()


func unboost() -> void:
	for bullet: BulletPingPong in _bullets:
		if bullet != null:
			bullet.unboost.rpc()
