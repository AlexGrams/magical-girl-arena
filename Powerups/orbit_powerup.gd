extends Powerup

var bullet_scene := "res://Powerups/orbit_bullet.tscn"
var sprite = preload("res://Coconut.png")
var bullet

signal picked_up_powerup(sprite)


func _ready() -> void:
	damage_levels = [20.0, 25.0, 25.0, 25.0, 100.0]
	powerup_name = "Orbit"


func activate_powerup():
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1,
		[
			bullet_scene, 
			Vector2.ZERO, 
			Vector2.ZERO, 
			damage_levels[min(damage_levels.size() - 1, current_level)], 
			[multiplayer.get_unique_id()]
		]
	)
	
	picked_up_powerup.emit(sprite)


func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, damage_levels[min(damage_levels.size() - 1, current_level)])
