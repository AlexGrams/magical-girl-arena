extends Bullet

## How close this bullet needs to get to its destination before switching targets.
const TOUCHING_DISTANCE_THRESHOLD: float = 25.0

## How many targets this bullet hits before it is destroyed.
@export var _max_bounces: int = 3
@onready var _squared_touching_distance_threshold: float = TOUCHING_DISTANCE_THRESHOLD ** 2
## Current remaining number of enemies this bullet can hit before it is destroyed.
@onready var _bounces: int = _max_bounces 

## Enemy that this bullet is moving towards.
var _target: Node = null


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _target != null:
		global_position += (_target.global_position - global_position).normalized() * speed * delta
		if _target.global_position.distance_squared_to(global_position) <= _squared_touching_distance_threshold:
			_find_new_target()
	else:
		_find_new_target()


## Set this bullet's target to the nearest enemy that isn't the current target.
func _find_new_target() -> void:
	# Destroy this bullet if we're out of bounces.
	if is_multiplayer_authority():
		_bounces -= 1
		if _bounces <= 0:
			queue_free()
			return
	
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
		
	if !enemies.is_empty():
		var nearest_enemy: Node2D = enemies[0]
		var nearest_distance = global_position.distance_squared_to(enemies[0].global_position)
		
		for enemy in enemies:
			if enemy == _target:
				continue
			
			var distance = global_position.distance_squared_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_enemy = enemy
				nearest_distance = distance
		
		_target = nearest_enemy


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Path to first target 
	):
		push_error("Malformed data array")
		return
	
	_target = get_tree().root.get_node(data[0])
	_is_owned_by_player = is_owned_by_player
	if not is_owned_by_player:
		push_warning("Not implemented for enemies.")
		return
