extends Powerup

## Time between creating puddles
@export var shoot_interval: float = 1.0
## Path to the Bullet-derived bullet scene.
@export var bullet_scene := ""

var is_on: bool = false

var _shoot_timer: float = 0
## How much damage the powerup does at its current level.
var _damage: float = 0.0

signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	powerup_name = "Trail"
	_damage = upgrade_curve.sample(float(current_level) / max_level)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, 
			[
				bullet_scene, 
				global_position, 
				Vector2.ZERO, 
				_damage,
				_is_owned_by_player,
				[]
			]
		)
		
		_shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit()


func deactivate_powerup():
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	_damage = upgrade_curve.sample(float(current_level) / max_level)
	powerup_level_up.emit(current_level, _damage)
