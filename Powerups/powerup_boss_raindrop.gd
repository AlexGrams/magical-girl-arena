extends Powerup
## Creates timed damage zones randomly around the boss and directly on players.


@export var _damage: float = 25.0
## Time in seconds between activation of bullets directly on the players.
@export var _targeted_shoot_interval: float = 2.0
## Time in seconds between activation of bullets spread randomly around the owner.
@export var _random_shoot_interval: float = 0.2
## Maximum distance in units away from the owner that random bullets can spawn.
@export var _random_shoot_radius: float = 1000.0
## UID of the scene for the powerup bullets
@export var _bullet_scene_uid := ""

var _targeted_shoot_timer: float = 0.0
var _random_shoot_timer: float = 0.0


func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)


func _process(delta: float) -> void:
	if is_on:
		_targeted_shoot_timer -= delta
		_random_shoot_timer -= delta
		if _targeted_shoot_timer <= 0.0:
			_shoot_targeted()
			_targeted_shoot_timer = _targeted_shoot_interval
		if _random_shoot_timer <= 0.0:
			_shoot_random()
			_random_shoot_timer = _random_shoot_interval
		


func activate_powerup():
	is_on = true
	_targeted_shoot_timer = _targeted_shoot_interval
	_random_shoot_timer = _random_shoot_interval


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false


## Spawn in timed activation bullets directly on the players.
func _shoot_targeted() -> void:
	# Some raindrops appear directly over all players that aren't downed.
	for player: PlayerCharacterBody2D in GameState.player_characters.values():
		if not player.is_down:
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [_bullet_scene_uid, 
				player.global_position, 
				Vector2.ZERO, 
				_damage, 
				false,
				[]
			])


## Spawn in timed activation bullets randomly around the boss.
func _shoot_random() -> void:
	var location: Vector2 = (
		global_position + 
		Vector2.UP.rotated(randf_range(0.0, 2 * PI)) * 
		randf_range(0.0, _random_shoot_radius)
	)
	
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
	1, [_bullet_scene_uid, 
		location, 
		Vector2.ZERO, 
		_damage, 
		false,
		[]
	])
