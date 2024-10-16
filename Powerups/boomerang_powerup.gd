extends Powerup

var bullet_scene = preload("res://Powerups/boomerang_bullet.tscn")
var sprite = preload("res://Peach.png")
var bullet
var powerup_name = "Boomerang"

signal picked_up_powerup(sprite)

func _ready():
	damage_levels = [20, 25, 50, 50, 50]
	
func activate_powerup():
	bullet = bullet_scene.instantiate()
	bullet.set_damage(damage_levels[min(4, current_level)])
	bullet.direction = Vector2.UP
	bullet.player = $"."
	bullet.global_position = global_position
	get_tree().root.add_child(bullet)
	
	picked_up_powerup.emit(sprite)

func level_up():
	current_level += 1
	if current_level < damage_levels.size():
		bullet.set_damage(damage_levels[min(4, current_level)])
