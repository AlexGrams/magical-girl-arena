class_name EXPOrb
extends Node2D


# Acceleration in units/second^2
const ACCELERATION = 1000.0

# The player that this EXP orb is moving towards.
var player: Node2D = null
# Ensures that this orb isn't counted multiple times by overlapping player characters.
var uncollected := true;
var velocity = 0.0


func _process(delta: float) -> void:
	if player != null:
		velocity += ACCELERATION * delta
		global_position = global_position.move_toward(player.global_position, delta * velocity)


# Destroys orb and adds EXP. Called when EXP orb touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if uncollected and is_multiplayer_authority() and area.get_collision_layer_value(4):
		uncollected = false
		GameState.collect_exp.rpc()
		destroy.rpc_id(1) 


# Can be called only once to set which player this orb is gravitating towards
@rpc("any_peer", "call_local")
func set_player(new_player: NodePath) -> void:
	if player == null:
		player = get_tree().root.get_node(new_player)


## Move this orb to a position
@rpc("authority", "call_local")
func teleport(pos: Vector2) -> void:
	global_position = pos


# Delete this EXP orb on all clients. Only call on the server.
@rpc("any_peer", "call_local")
func destroy() -> void:
	self.queue_free()
