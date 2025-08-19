class_name PowerupBoomerang
extends Powerup


## The boomerang controller.
@export var _controller_bullet_scene: String = ""
## The actual boomerang bullet that does damage.
@export var _boomerang_bullet_scene: String = ""
## Time in seconds between when boomerangs are sent out when this powerup is upgraded to have multiple boomerangs.
@export var _upgraded_fire_interval: float = 1.0

var sprite = preload("res://Peach.png")

var _boomerang_controller: BulletBoomerangController

signal picked_up_powerup(sprite)


func set_boomerang_controller(value: BulletBoomerangController) -> void:
	_boomerang_controller = value


func _ready():
	pass


func activate_powerup():
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [_controller_bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				false,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[$"..".get_path(), _upgraded_fire_interval, _boomerang_bullet_scene]
			]
		)
	else:
		push_warning("Not implemented!")
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [_controller_bullet_scene, 
				global_position, 
				Vector2.UP, 
				_get_damage_from_curve(), 
				false,
				_is_owned_by_player,
				-1,
				-1,
				[$"..".get_path()]
			]
		)
	
	picked_up_powerup.emit(sprite)


# Does nothing. The bullet destroys itself based off of the player's "died" signal.
func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	_boomerang_controller.boost()


func unboost() -> void:
	_boomerang_controller.unboost()
