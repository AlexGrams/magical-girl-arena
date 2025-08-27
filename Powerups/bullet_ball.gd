extends Bullet


var _owning_player: PlayerCharacterBody2D = null
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning player
	):
		push_error("Malformed data array")
		return
	
	_owning_player = get_node(data[0])
	_is_owned_by_player = is_owned_by_player
	
	if _owning_player != null and is_multiplayer_authority():
		_owning_player.died.connect(func():
			queue_free()
		)
	
	# The Powerup child is not replicated, so only the client which owns this character has it.
	var ball_powerup: PowerupBall = _owning_player.get_node_or_null("PowerupBall")
	if ball_powerup != null:
		ball_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				_level_up.rpc(new_level, new_damage)
		)
		
		# Update crit values
		ball_powerup.crit_changed.connect(
			func(crit_chance: float, crit_multiplier: float):
				_crit_chance = crit_chance
				_crit_multiplier = crit_multiplier
		)


## This bullet's owner has leveled up its corresponding powerup.
@rpc("any_peer", "call_local")
func _level_up(_new_level: int, new_damage: float):
	collider.damage = new_damage
