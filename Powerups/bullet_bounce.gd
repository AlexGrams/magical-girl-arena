extends Bullet

## How close this bullet needs to get to its destination before switching targets.
const TOUCHING_DISTANCE_THRESHOLD: float = 25.0


## The collision shape for finding enemies within range.
@export var _enemy_mask_collision_shape: Area2D = null
@onready var _squared_touching_distance_threshold: float = TOUCHING_DISTANCE_THRESHOLD ** 2
## Current remaining number of enemies this bullet can hit before it is destroyed.
var _bounces: int

## Enemy that this bullet is moving towards.
var _target: Node = null
## True when we need to update this bullet's target next physics frame.
var _update_target: bool = false



func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _target != null:
		var direction = (_target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		if _target.global_position.distance_squared_to(global_position) <= _squared_touching_distance_threshold:
			_update_target = true
		sprite.rotation = direction.angle() + deg_to_rad(0)
	else:
		_update_target = true


func _physics_process(_delta: float) -> void:
	# _find_new_target is called in the physics process since it is possible for it to be destroyed
	# this frame. If it is destroyed before collisions are updated, then the last enemy that it 
	# touched won't take damage.
	if _update_target:
		_find_new_target()
		_update_target = false


## Set this bullet's target to the nearest enemy that isn't the current target.
func _find_new_target() -> void:
	# Destroy this bullet if we're out of bounces.
	if is_multiplayer_authority():
		_bounces -= 1
		if _bounces <= 0:
			queue_free()
			return
	
	var enemies: Array[Area2D] = _enemy_mask_collision_shape.get_overlapping_areas()
	
	if !enemies.is_empty():
		var nearest_enemy: Node2D = null
		var nearest_distance = INF 
		
		for enemy_area: Area2D in enemies:
			var enemy: Node = enemy_area.get_parent()
			if enemy == _target:
				continue
			if enemy is Enemy:
				var distance = global_position.distance_squared_to(enemy.global_position)
				if distance < nearest_distance:
					nearest_enemy = enemy
					nearest_distance = distance
		
		_target = nearest_enemy
	
	# There were no valid enemies within range, so destroy this bullet.
	if _target == null and is_multiplayer_authority():
		queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or typeof(data[0]) != TYPE_NODE_PATH	# Path to first target
		or typeof(data[1]) != TYPE_INT			# Max # of bounces
	):
		push_error("Malformed data array")
		return
	
	_bounces = data[1]
	_target = get_tree().root.get_node(data[0])
	_is_owned_by_player = is_owned_by_player
	if not is_owned_by_player:
		push_warning("Not implemented for enemies.")
		return
