class_name EnemyBoss
extends Enemy
## A special enemy that ends the game when it is defeated.

var _hud_canvas_layer: HUDCanvasLayer = null


func _ready() -> void:
	super()
	
	_hud_canvas_layer = get_tree().root.get_node("Playground/CanvasLayer")
	_hud_canvas_layer.show_boss_health_bar(float(health) / max_health)
	
	# Win the game when the boss dies
	died.connect(func(_enemy):
		if multiplayer.is_server():
			GameState._game_over.rpc(true)
	)


func _physics_process(delta: float) -> void:
	super(delta)


## Only call on the server. Deals damage to this Boss. Update health bars on all clients.
@rpc("any_peer", "call_local")
func _take_damage(damage: float) -> void:
	super(damage)
	
	_hud_canvas_layer.update_boss_health_bar.rpc(float(health) / max_health)


## Delete the boss. Only call on the server.
@rpc("any_peer", "call_local")
func die() -> void:
	if not is_multiplayer_authority():
		return
	
	died.emit(self)
	_hud_canvas_layer.hide_boss_health_bar.rpc()
	queue_free()


## Boss enemy cannot be made into an ally.
func make_ally(_new_lifetime: float, _new_damage: float) -> void:
	pass
