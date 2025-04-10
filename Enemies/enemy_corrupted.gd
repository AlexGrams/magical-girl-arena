class_name EnemyCorrupted
extends EnemyRanged
## A corrupted magical girl enemy. Can use powerups and abilities like the player.

## How long this corrupted enemy stays in the game before leaving. Doesn't drop loot if time runs out.
@export var corrupted_lifetime: float = 0.0
## Scene for the Powerup to give to this enemy when it spawns.
@export var default_powerup_path: String = ""

# How much time this corrupted enemy has left in the game.
var current_lifetime: float = 0.0

var _hud_canvas_layer: HUDCanvasLayer = null


func _ready() -> void:
	super()
	
	current_lifetime = corrupted_lifetime
	
	_hud_canvas_layer = get_tree().root.get_node("Playground/CanvasLayer")
	_hud_canvas_layer.show_boss_health_bar(float(health) / max_health)
	
	var default_powerup: PowerupData = load(default_powerup_path)
	if default_powerup != null:
		_add_powerup(default_powerup.scene)


func _process(delta: float) -> void:
	super(delta)
	
	current_lifetime -= delta
	if current_lifetime <= 0.0 and is_multiplayer_authority():
		_leave()


func _physics_process(delta: float) -> void:
	super(delta)


func shoot() -> void:
	pass


## Only call on the server. Deals damage to this corrupted enemy. Update health bars on all clients.
@rpc("any_peer", "call_local")
func _take_damage(damage: float) -> void:
	super(damage)
	
	_hud_canvas_layer.update_boss_health_bar.rpc(float(health) / max_health)


## Does nothing since corrupted Enemies cannot be made into allies.
func make_ally(_new_lifetime: float, _new_damage: float) -> void:
	die()


## Delete the corrupted enemy. Only call on the server.
@rpc("any_peer", "call_local")
func die() -> void:
	if not is_multiplayer_authority():
		return
	
	super()
	_hud_canvas_layer.hide_boss_health_bar.rpc()


# Despawn the corrupted enemy. Different from dying as it doesn't drop loot.
@rpc("any_peer", "call_local")
func _leave() -> void:
	if not is_multiplayer_authority():
		return
	
	_hud_canvas_layer.hide_boss_health_bar.rpc()
	queue_free()


## Spawns a Powerup Pickup after being defeated if at least one player can use it. 
## Otherwise, gives a lot of experience.
func _spawn_loot() -> void:
	get_tree().root.get_node("Playground").spawn_corrupted_enemy_loot(default_powerup_path, global_position)
