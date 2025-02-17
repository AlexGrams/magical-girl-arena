extends Powerup

@export var shoot_interval: float  = 0.25
@export var bullet_scene := "res://Powerups/revolving_bullet.tscn"

# TODO: Might not be used anymore
var sprite = preload("res://Orange.png")
var is_on := false
var shoot_timer: float = 0
var direction := Vector2.RIGHT
var bullet_damage: float

signal picked_up_powerup(sprite)


func _ready() -> void:
	max_level = 15
	powerup_name = "Revolving"
	upgrade_curve = load("res://Curves/upgrade_revolving.tres")
	
	damage_levels = [25, 25, 50, 50, 100]
	bullet_damage = damage_levels[min(4, current_level)]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_on:
		shoot_timer += delta
		if shoot_timer > shoot_interval:
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1, [bullet_scene, 
					global_position, 
					direction, 
					bullet_damage, 
					[_is_owned_by_player]
				]
			)
			
			direction = direction.rotated(deg_to_rad(30)).normalized()
			
			shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit(sprite)


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	bullet_damage = upgrade_curve.sample(float(current_level) / max_level)
	powerup_level_up.emit(current_level, bullet_damage)
