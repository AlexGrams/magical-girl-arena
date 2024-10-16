extends Powerup

var bullet_scene = preload("res://Powerups/orbit_bullet.tscn")
var sprite = preload("res://Coconut.png")
var is_on:bool = false
var bullet
var powerup_name = "Orbit"

signal picked_up_powerup(sprite)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_levels = [20, 25, 25, 25, 100]

func hide_sprite():
	$Sprite2D.hide()
	
func activate_powerup():
	position = Vector2(0, 0)
	
	bullet = bullet_scene.instantiate()
	bullet.radius = 74
	add_child(bullet)
	
	picked_up_powerup.emit(sprite)

func reparent_and_add_bullet(area):
	reparent(area.get_parent(), false)
	position = Vector2(0, 0)
	hide_sprite()
	
	bullet = bullet_scene.instantiate()
	bullet.radius = 74
	add_child(bullet)

func level_up():
	current_level += 1
	bullet.set_damage(damage_levels[min(4, current_level)])
