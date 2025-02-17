extends Powerup

@export var shoot_interval: float = 1.0
@export var bullet_damage: float = 50.0
@export var bullet_scene := "res://Powerups/bullet.tscn"

var is_on: bool = false
var shoot_timer: float = 0

signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	powerup_name = "Shooting"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		var direction = (get_global_mouse_position() - self.global_position).normalized()
		var bullet_position = self.global_position + (direction * 100)
		
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [bullet_scene, 
				bullet_position, 
				direction, 
				bullet_damage, 
				[]
			]
		)
		
		shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit()


func deactivate_powerup():
	is_on = false
	shoot_timer = 0.0


func level_up():
	pass
	#current_level += 1
	#bullet_damage = damage_levels[min(4, current_level)]
