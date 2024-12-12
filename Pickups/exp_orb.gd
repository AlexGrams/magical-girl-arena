# NOTE: Doesn't do anything right now. Disabled in case physics-based solution for
# exp orb gravity doesn't work.

extends Node2D

# Acceleration in units/second^2
const acceleration = 1000.0

var velocity = 0.0
# The player that this EXP orb is moving towards.
var player: Node2D = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if player != null:
		#velocity += acceleration * delta
		#global_position = global_position.move_toward(player.global_position, delta * velocity)

# Can be called only once to set which player this orb is gravitating towards
func set_player(new_player: Node2D) -> void:
	if player == null:
		player = new_player
