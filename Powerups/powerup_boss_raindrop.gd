extends Powerup
## Creates timed damage zones randomly around the boss and directly on players.


@export var _damage: float = 25.0
## Time in seconds between activations
@export var _shoot_interval: float = 1.0
## UID of the scene for the powerup bullets
@export var _bullet_scene_uid := ""

var _shoot_timer: float = 0.0


func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)


func _process(delta: float) -> void:
	if is_on:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_shoot()
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


## Spawn in timed raindrop bullets.
func _shoot() -> void:
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
