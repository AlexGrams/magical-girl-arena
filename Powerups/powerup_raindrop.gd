extends Powerup
## Creates timed damage zones randomly around the boss and directly on players.


## Time in seconds between activation of bullets directly on the players.
@export var _shoot_interval: float = 2.0
## Maximum distance at which an Enemy can be from the player in order for this powerup to target them.
@export var _range: float = 1000.0
## UID of the scene for the powerup bullets
@export var _bullet_scene_uid := ""

var _shoot_timer: float = 0.0
var _bullet_spawner: BulletSpawner = null
var _range_squared: float = 1.0


func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
	
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")
	_range_squared = _range * _range


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var target: Node2D = _find_nearest_target()
		if target != null and global_position.distance_squared_to(target.global_position) <= _range_squared:
			_bullet_spawner.request_spawn_bullet.rpc_id(
			1, [_bullet_scene_uid, 
				target.global_position, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[target.get_path()]
			])
		_shoot_timer = _shoot_interval


func activate_powerup():
	is_on = true
	_shoot_timer = _shoot_interval


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
