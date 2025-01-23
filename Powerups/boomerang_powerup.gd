extends Powerup


const BOOMERANG_MAX_LEVEL: int = 1

var bullet_scene := "res://Powerups/boomerang_bullet.tscn"
var sprite = preload("res://Peach.png")
# The single bullet instance used by this Powerup. The boomerang is never destroyed.
var bullet: Object

signal picked_up_powerup(sprite)


func _ready():
	damage_levels = [20.0, 25.0, 50.0, 75.0, 100.0]
	max_level = BOOMERANG_MAX_LEVEL
	powerup_name = "Boomerang"


func activate_powerup():
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [bullet_scene, 
			global_position, 
			Vector2.UP, 
			damage_levels[min(4, current_level)], 
			[$"..".get_path()]
		]
	)
	
	picked_up_powerup.emit(sprite)


# Does nothing. The bullet destroys itself based off of the player's "died" signal.
func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, damage_levels[min(damage_levels.size() - 1, current_level)])
