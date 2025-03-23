extends Powerup

var bullet_scene := "res://Powerups/orbit_bullet.tscn"
var sprite = preload("res://Coconut.png")
var bullet

signal picked_up_powerup(sprite)


func _ready() -> void:
	damage_levels = [20.0, 25.0, 25.0, 25.0, 100.0]


func activate_powerup():
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				upgrade_curve.sample(float(current_level) / max_level), 
				_is_owned_by_player,
				[multiplayer.get_unique_id()]
			]
		)
	else:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				upgrade_curve.sample(float(current_level) / max_level), 
				_is_owned_by_player,
				[get_parent().get_path()]
			]
		)
	
	picked_up_powerup.emit(sprite)


func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, upgrade_curve.sample(float(current_level) / max_level))
