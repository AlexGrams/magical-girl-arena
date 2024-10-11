extends Sprite2D

@export var shoot_interval = 0.25
var bullet_scene = preload("res://Powerups/revolving_bullet.tscn")
var sprite = preload("res://Orange.png")
var is_on:bool = false
var shoot_timer = 0
var direction = Vector2.RIGHT

signal picked_up_powerup(sprite)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_on:
		shoot_timer += delta
		if shoot_timer > shoot_interval:
			var bullet = bullet_scene.instantiate()
			bullet.direction = direction
			direction = direction.rotated(1).normalized()
			# This is global so that when the powerup is picked up,
			# it uses the player's position
			bullet.global_position = global_position
			bullet.scale = Vector2(2, 2)
			get_tree().root.add_child(bullet)
			shoot_timer = 0

func hide_sprite():
	hide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_on:
		reparent.call_deferred(area.get_parent(), false)
		position = Vector2(0, 0)
		hide_sprite()
		is_on = true
		picked_up_powerup.emit(sprite)
