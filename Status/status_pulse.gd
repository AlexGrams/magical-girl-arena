class_name StatusPulse
extends Status
## Status applied to allies hit by a Pulse bullet. Causes a pulse to eminate from them at the next 
## pulse interval.


const _PULSE_BULLET_SCENE: String = "res://Powerups/bullet_pulse.tscn"

## The multiplayer ID of the player who started this Pulse status effect chain.
var _owner_id: int = 0
## Damage of the resulting Pulse bullet.
var _damage: float = 0.0
## How many stacks of this status there are.
var _stacks: int = 1


func get_status_name() -> String:
	return "Pulse"


func set_properties(id: int, damage: float) -> void:
	_owner_id = id
	duration = GameState.time - int(GameState.time)
	_damage = damage 
	GameState.player_characters[_owner_id].delay_pulse.rpc_id(_owner_id)


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	super(delta)


## Create another bullet.
func deactivate() -> void:
	get_parent().remove_status(self)
	
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, 
		[
			_PULSE_BULLET_SCENE, 
			get_parent().global_position, 
			Vector2.ZERO, 
			_damage, 
			true,
			-1,
			-1,
			[get_parent().get_path(), _owner_id, _stacks]
		]
	)


## Stack this status effect, where each unique hit causes the Pulse created after this status wears off
## to be larger.
func stack() -> void:
	_stacks += 1
