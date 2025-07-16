class_name StatusPulse
extends Status
## Status applied to allies hit by a Pulse bullet. Causes a pulse to eminate from them at the next 
## pulse interval.


const _PULSE_BULLET_SCENE: String = "res://Powerups/bullet_pulse.tscn"

## The multiplayer ID of the player who started this Pulse status effect chain.
var _owner_id: int = 0
## Damage of the resulting Pulse bullet.
var _damage: float = 0.0


func get_status_name() -> String:
	return "Pulse"


func set_properties(id: int, damage: float) -> void:
	_owner_id = id
	duration = 1.0 - (GameState.time - int(GameState.time))
	_damage = damage 


func _ready() -> void:
	pass # Replace with function body.
	print("Pulse status")


func _process(delta: float) -> void:
	super(delta)


## Create another bullet.
func deactivate() -> void:
	get_parent().remove_status(self)
	
	#get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		#1, 
		#[
			#_PULSE_BULLET_SCENE, 
			#get_parent().global_position, 
			#Vector2.ZERO, 
			#_damage, 
			#true,
			#-1,
			#-1,
			#[_owner_id]
		#]
	#)
