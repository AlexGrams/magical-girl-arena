class_name EnemyBoss
extends Enemy
## A special enemy that ends the game when it is defeated.


func _physics_process(delta: float) -> void:
	super(delta)


# Probably should not be called. Boss enemies cannot be made into allies.
func make_ally(_new_lifetime: float, _new_damage: float) -> void:
	if is_multiplayer_authority():
		die.rpc_id(1)
