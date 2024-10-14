extends Powerup

var bullet_scene = preload("res://Powerups/boomerang_bullet.tscn")
var sprite = preload("res://Peach.png")
var is_on:bool = false
var bullet

signal picked_up_powerup(sprite)

func _ready():
	damage_levels = [20, 25, 50, 50, 50]
	
func hide_sprite():
	$Sprite2D.hide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_on:
		is_on = true
		reparent_and_add_bullet.call_deferred(area)
		picked_up_powerup.emit(sprite)

func reparent_and_add_bullet(area):
	reparent(area.get_parent(), false)
	position = Vector2(0, 0)
	hide_sprite()
	
	bullet = bullet_scene.instantiate()
	bullet.set_damage(damage_levels[min(4, current_level)])
	bullet.direction = Vector2.UP
	bullet.player = $"."
	bullet.global_position = global_position
	get_tree().root.add_child(bullet)

func level_up():
	current_level += 1
	if current_level < damage_levels.size():
		bullet.set_damage(damage_levels[min(4, current_level)])
