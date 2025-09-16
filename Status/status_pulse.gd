class_name StatusPulse
extends Status
## Status applied to allies hit by a Pulse bullet. Causes a pulse to eminate from them at the next 
## pulse interval.


const _PULSE_BULLET_SCENE: String = "res://Powerups/bullet_pulse.tscn"

## The multiplayer ID of the player who started this Pulse status effect chain.
var _owner_id: int = 0
## Index of this powerup on its owner.
var _powerup_index: int = -1
## Damage of the resulting Pulse bullet.
var _damage: float = 0.0
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
## True if owning player has powerup level 3 or higher.
var _is_level_three: bool = false
## Does the Powerup owner have the Area Size charm?
var _area_size_boost: bool = false
## How many stacks of this status there are.
var _stacks: int = 1


func get_status_name() -> String:
	return "Pulse"


func set_properties(
		id: int, 
		powerup_index: int,
		damage: float, 
		is_level_three: bool, 
		crit_chance: float, 
		crit_multiplier: float,
		area_size_boost: bool
	) -> void:
	
	_owner_id = id
	_powerup_index = powerup_index
	_damage = damage 
	_is_level_three = is_level_three
	_crit_chance = crit_chance
	_crit_multiplier = crit_multiplier
	_area_size_boost = area_size_boost
	
	duration = GameState.time - int(GameState.time)
	# Special duration calculation if time is negative, after the boss has spawned.
	if duration < 0.0:
		duration = 1.0 + duration


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	super(delta)


## Create another bullet.
func deactivate() -> void:
	get_parent().remove_status(self)
	
	var crit: bool = randf() < _crit_chance
	var total_damage: float = _damage * (1.0 if not crit else _crit_multiplier)
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, 
		[
			_PULSE_BULLET_SCENE, 
			get_parent().global_position, 
			Vector2.ZERO, 
			total_damage, 
			crit,
			true,
			_owner_id,
			_powerup_index,
			[
				get_parent().get_path(), 
				_owner_id, 
				_stacks, 
				_is_level_three,
				_crit_chance,
				_crit_multiplier,
				_area_size_boost
			]
		]
	)


## Stack this status effect, where each unique hit causes the Pulse created after this status wears off
## to be larger.
func stack() -> void:
	pass
	# TODO: Figure out what to do for this powerup stacking.
	#_stacks += 1
