extends Powerup
## A map-wide attack does massive damage to all players that aren't behind a terrain object.
## Destroys the bullets created by powerup_boss_terrain.


@export var _damage: float = 150.0
@export var _bullet_scene: String = ""


func _ready() -> void:
	_is_owned_by_player = false


func activate_powerup():
	GameState.playground.get_node("BulletSpawner").request_spawn_bullet.rpc_id(
		1,
		[
			_bullet_scene, 
			global_position, 
			Vector2.ZERO, 
			_damage, 
			false,
			_is_owned_by_player,
			-1,
			-1,
			[]
		]
	)


func deactivate_powerup():
	pass
