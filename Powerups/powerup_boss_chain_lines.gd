extends Powerup
## A map-wide attack that produces vertical or horizontal chains, limiting player 
## movement until they go away.


## Damage for touching a chain.
@export var _damage: float = 50.0
## How many lines are produces per attack.
@export var _count: int = 6
## Distance between each line.
@export var _chain_separation: float = 500.0
@export var _bullet_scene := ""

## How many times this powerup has been activated. Does different things depending on number.
var _activations: int = 0


func _ready() -> void:
	_is_owned_by_player = false


func activate_powerup():
	_activations += 1
	if _activations == 1:
		shoot(true)
	elif _activations == 2:
		shoot(false)
	elif _activations >= 3:
		shoot(true)
		shoot(false)


func deactivate_powerup():
	pass


func shoot(is_horizontal: bool) -> void:
	# Chains are spaced evenly apart
	var chain_rotation: Vector2 = Vector2.RIGHT if is_horizontal else Vector2.UP
	var chain_position: Vector2 = get_parent().global_position
	var half_total_distance_covered = _chain_separation * (_count - 1) / 2
	if is_horizontal:
		chain_position.y -= half_total_distance_covered
	else:
		chain_position.x -= half_total_distance_covered
	
	for i in range(_count):
		GameState.playground.get_node("BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				_bullet_scene, 
				chain_position, 
				chain_rotation, 
				_damage, 
				false,
				_is_owned_by_player,
				-1,
				-1,
				[]
			]
		)
		
		if is_horizontal:
			chain_position.y += _chain_separation
		else:
			chain_position.x += _chain_separation
