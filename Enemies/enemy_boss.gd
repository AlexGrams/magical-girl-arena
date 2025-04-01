class_name EnemyBoss
extends Enemy
## A special enemy that ends the game when it is defeated.


func _ready() -> void:
	super()
	
	# Win the game when the boss dies
	died.connect(func(_enemy):
		if multiplayer.is_server():
			GameState._game_over.rpc(true)
	)


func _physics_process(delta: float) -> void:
	super(delta)


## Delete the boss. Only call on the server.
@rpc("any_peer", "call_local")
func die() -> void:
	if not is_multiplayer_authority():
		return
	
	died.emit(self)
	queue_free()


## Boss enemy cannot be made into an ally.
func make_ally(_new_lifetime: float, _new_damage: float) -> void:
	pass
