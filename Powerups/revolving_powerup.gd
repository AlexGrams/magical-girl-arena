extends Powerup

@export var shoot_interval = 0.25
var bullet_scene = preload("res://Powerups/revolving_bullet.tscn")
var sprite = preload("res://Orange.png")
var is_on:bool = false
var shoot_timer = 0
var direction = Vector2.RIGHT
var bullet_damage
var powerup_name = "Revolving"

signal picked_up_powerup(sprite)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_levels = [25, 25, 50, 50, 100]
	bullet_damage = damage_levels[min(4, current_level)]

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
			bullet.set_damage(bullet_damage)
			get_tree().root.add_child(bullet)
			shoot_timer = 0

func activate_powerup():
	is_on = true
	picked_up_powerup.emit(sprite)

func level_up():
	current_level += 1
	bullet_damage = damage_levels[min(4, current_level)]
