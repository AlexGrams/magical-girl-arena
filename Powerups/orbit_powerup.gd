extends Sprite2D

var bullet_scene = preload("res://Powerups/orbit_bullet.tscn")
var sprite = preload("res://Coconut.png")
var is_on:bool = false

signal picked_up_powerup(sprite)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hide_sprite():
	$Sprite2D.hide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_on:
		reparent_and_add_bullet.call_deferred(area)
		is_on = true
		picked_up_powerup.emit(sprite)

func reparent_and_add_bullet(area):
	reparent(area.get_parent(), false)
	position = Vector2(0, 0)
	hide_sprite()
	
	var bullet = bullet_scene.instantiate()
	bullet.radius = 74
	add_child(bullet)
