extends BulletContinuous
## Damages enemies and heals allies while touching it


## Time in seconds between healing allies.
@export var _heal_interval: float = 1.0
## How much healing is done each healing tick.
@export var _heal_amount: float = 3.0

## The ult bullet only keeps track of when it is touching the local player for healing.
var _local_player: PlayerCharacterBody2D = null
var _is_local_player_colliding: bool = false
var _heal_timer: float = 0.0


func _ready() -> void:
	_local_player = GameState.get_local_player()


func _process(delta: float) -> void:
	super(delta)
	
	_heal_timer += delta
	if _heal_timer >= _heal_interval:
		if _is_local_player_colliding:
			_local_player.take_damage(-_heal_amount)
		_heal_timer = 0.0


func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_FLOAT	# Lifetime
	):
		push_error("Malformed bullet setup data array.")
		return
	
	lifetime = data[0]
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		_modify_collider_to_harm_players()
	
	# Disable process and collision signals for non-owners.
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process(false)


## Apply damage continually to any overlapping Enemies.
func _on_area_2d_entered(area: Area2D) -> void:
	super(area)
	
	if area.get_parent() == _local_player:
		_is_local_player_colliding = true


func _on_area_2d_exited(area: Area2D) -> void:
	super(area)
	
	if area.get_parent() == _local_player:
		_is_local_player_colliding = false
