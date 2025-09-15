class_name PowerupPingPong
extends Powerup


var bullet_scene := "res://Powerups/bullet_pingpong.tscn"

var _bullets: Array[BulletPingPong] = []

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float) 


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_crit_multiplier(new_multiplier: float) -> void:
	super(new_multiplier)
	crit_changed.emit(crit_chance, crit_multiplier)


func add_bullet(new_bullet: BulletPingPong) -> void:
	_bullets.append(new_bullet)


func _ready():
	super()


func activate_powerup():
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, 
			[
				bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				false,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[$"..".get_path()]
			]
		)
	else:
		push_error("Enemy PingPong not implemented")


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


func boost_haste() -> void:
	for bullet: BulletPingPong in _bullets:
		if bullet != null:
			bullet.boost.rpc()


func boost_energy() -> void:
	pass
