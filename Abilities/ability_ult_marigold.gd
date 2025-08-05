extends Ability


@export var _bullet_scene := ""
@export var _duration: float = 10.0

var _owner: PlayerCharacterBody2D = null


func _ready() -> void:
	super()
	
	_owner = get_parent()


func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
		1,
		[
			_bullet_scene, 
			_owner.global_position, 
			Vector2.ZERO, 
			0.0, 
			true,
			multiplayer.get_unique_id(),
			-1,
			[_duration]
		]
	)
	
	# Apply boost to all turrets that spawn for some time after the ultimate is used.
	var turret_powerup: PowerupTurret = null
	for powerup: Powerup in _owner.powerups:
		if powerup is PowerupTurret:
			turret_powerup = powerup
			break
	if turret_powerup:
		turret_powerup.set_ultimate_boost_duration(_duration)


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	pass
