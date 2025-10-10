class_name EnemyBoss
extends Enemy
## A special enemy that ends the game when it is defeated.


## Multiplier by which to increase boss health by depending on the number of players in the game.
@export var _health_scale: Array[float] = [1.0, 1.0, 1.0, 1.0]
## Pointer icon for this Boss.
@export var _icon: Texture2D = null


func set_knockback(_vector: Vector2, _duration: float) -> void:
	pass


func _ready() -> void:
	super()
	
	# Scale health for number of players. Overrides how base Enemy scales health.
	max_health = int(base_health * _health_scale[GameState.connected_players - 1])
	health = max_health
	
	_hud_canvas_layer = GameState.playground.hud_canvas_layer
	_hud_canvas_layer.show_boss_health_bar(float(health) / max_health)
	_hud_canvas_layer.add_node_to_point_to(self, _icon)
	
	#await get_tree().create_timer(1.0, false).timeout
	#
	#if is_multiplayer_authority():
		#take_damage(health)


func _physics_process(delta: float) -> void:
	super(delta)


## Only call on the server. Deals damage to this Boss. Update health bars on all clients.
@rpc("any_peer", "call_local")
func _take_damage(damage: float, is_crit: bool = false) -> void:
	super(damage, is_crit)
	
	_update_boss_health_bar.rpc(float(health) / max_health, true)


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
