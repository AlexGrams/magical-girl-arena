extends Powerup

# Time in seconds between creating a bullet.
@export var shoot_interval = 1.0
@export var bullet_scene := ""
# TODO: Do we even need this? If so, it should probably go in Powerup and not here.
#@export var sprite: Resource = null
var bullet
var is_on := false
var shoot_timer: float = 0.0


func _ready() -> void:
	max_level = 15
	powerup_name = "Scythe"
	upgrade_curve = load("res://Curves/upgrade_orbit.tres")


func _process(delta: float) -> void:
	if not is_on:
		return
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		var direction = (get_global_mouse_position() - self.global_position).normalized()
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				direction, 
				upgrade_curve.sample(float(current_level) / max_level), 
				[multiplayer.get_unique_id()]
			]
		)
		
		shoot_timer = 0


func activate_powerup():
	is_on = true


func deactivate_powerup():
	is_on = false
	shoot_timer = 0.0


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, upgrade_curve.sample(float(current_level) / max_level))
