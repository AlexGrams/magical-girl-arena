extends Powerup

var bullet_scene = preload("res://Powerups/orbit_bullet.tscn")
var sprite = preload("res://Coconut.png")
var bullet
var powerup_name = "Orbit"

signal picked_up_powerup(sprite)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_levels = [20, 25, 25, 25, 100]
	
func activate_powerup():
	bullet = bullet_scene.instantiate()
	bullet.radius = 74
	add_child(bullet)
	
	picked_up_powerup.emit(sprite)

func level_up():
	current_level += 1
	bullet.set_damage(damage_levels[min(4, current_level)])
