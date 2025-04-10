class_name EnemyCorrupted
extends EnemyRanged
## A corrupted magical girl enemy. Can use powerups and abilities like the player.

## How long this corrupted enemy stays in the game before leaving. Doesn't drop loot if time runs out.
@export var corrupted_lifetime: float = 0.0
## Scene for the Powerup to give to this enemy when it spawns.
@export var default_powerup_path: String = ""

# How much time this corrupted enemy has left in the game.
var current_lifetime: float = 0.0

var _signature_powerup_orb: PackedScene = preload("res://Pickups/signature_powerup_orb.tscn")
var _big_exp_orb: PackedScene = preload("res://Pickups/exp_orb_big.tscn")
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


## Asynchronously set up the loot orb dropped by this Corrupted Enemy.
func _set_up_signature_powerup_orb(signature_powerup_orb: SignaturePowerupOrb) -> void:
	signature_powerup_orb.teleport.rpc(global_position)
	signature_powerup_orb.set_powerup.rpc(default_powerup_path)


## Only call on the server. Deals damage to this corrupted enemy. Update health bars on all clients.
@rpc("any_peer", "call_local")
func _take_damage(damage: float) -> void:
	super(damage)
	
	_hud_canvas_layer.update_boss_health_bar.rpc(float(health) / max_health)


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
	# See if at least one Player can pick up the Powerup
		# If so, the Pickup and RPC it to make it whatever its supposed to be
	# Otherwise, spawn the big EXP orb.
	var signature_powerup_orb: SignaturePowerupOrb = _signature_powerup_orb.instantiate()
	
	signature_powerup_orb.global_position = global_position
	signature_powerup_orb.tree_entered.connect(
		func(): _set_up_signature_powerup_orb(signature_powerup_orb)
		, CONNECT_DEFERRED
	)
	get_tree().root.get_node("Playground").call_deferred("add_child", signature_powerup_orb, true)
