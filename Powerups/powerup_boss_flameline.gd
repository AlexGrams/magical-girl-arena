extends Powerup


@export var _damage: float = 25.0
@export var _bullet_scene := ""
## The instantiated bullets controlled by this powerup. Orbit bullets register themselves
## with this powerup after they spawn.
var _bullets: Array[Bullet] = [] 


## Add a reference to an instantated bullet.
func add_bullet(bullet: Bullet) -> void:
	_bullets.append(bullet)


func _ready() -> void:
	_is_owned_by_player = false


func activate_powerup():
	print("Flame line active")
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1,
		[
			_bullet_scene, 
			Vector2.ZERO, 
			Vector2.RIGHT, 
			_damage, 
			_is_owned_by_player,
			-1,
			-1,
			[get_parent().get_path()]
		]
	)


func deactivate_powerup():
	pass
