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
signal disabled()
signal crit_changed(new_crit_chance: float, new_crit_multiplier: float) 


func set_boomerang_controller(value: BulletBoomerangController) -> void:
	_boomerang_controller = value


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_crit_multiplier(new_multiplier: float) -> void:
	super(new_multiplier)
	crit_changed.emit(crit_chance, crit_multiplier)


func _ready():
	super()


func activate_powerup():
	super()
	
	if _deactivation_sources > 0:
		return
	
	if _is_owned_by_player:
		var spawn_boomerang: Callable = func():
			GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
				1, [_controller_bullet_scene, 
					global_position, 
					Vector2.UP, 
					_get_damage_from_curve(), 
					false,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[
						$"..".get_path(), 
						_upgraded_fire_interval, 
						_boomerang_bullet_scene
					]
				]
			)
		spawn_boomerang.call_deferred()
	else:
		push_error("Boomerang not implemented for enemies!")
	
	picked_up_powerup.emit(sprite)


func deactivate_powerup():
	super()
	disabled.emit()


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if is_signature and current_level == max_level:
		_boomerang_controller.activate_signature.rpc_id(1)


func boost() -> void:
	if _boomerang_controller != null:
		_boomerang_controller.boost()


func unboost() -> void:
	if _boomerang_controller != null:
		_boomerang_controller.unboost()


func boost_fire_rate() -> void:
	_boomerang_controller.boost_fire_rate()
