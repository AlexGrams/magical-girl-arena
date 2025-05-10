extends Powerup
## Creates timed damage zones randomly around the boss and directly on players.


@export var _damage: float = 25.0
## Time in seconds between activation of bullets directly on the players.
@export var _shoot_interval: float = 2.0
## Maximum distance in units away from the owner that random bullets can spawn.
@export var _random_shoot_radius: float = 1000.0
## UID of the scene for the powerup bullets
@export var _bullet_scene_uid := ""

var _shoot_timer: float = 0.0
var _bullet_spawner: BulletSpawner = null


func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
	
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var target: Node2D = _find_nearest_target()
		if target != null:
			_bullet_spawner.request_spawn_bullet.rpc_id(
			1, [_bullet_scene_uid, 
				target.global_position, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				[target]
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
