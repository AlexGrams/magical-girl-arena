extends Bullet
## NOTE: Bullet position is not replicated completely on clients. Damage is only done
## by the server, and clients' views of the bullets can be desynced. Shouldn't be a 
## big issue since it's just visual, and it shouldn't happen all the time.


## How close this bullet needs to get to its destination before switching targets.
const TOUCHING_DISTANCE_THRESHOLD: float = 25.0

## The collision shape for finding enemies within range.
@export var _enemy_mask_collision_shape: Area2D = null
# Rotation in degrees for any necessary rotation offsets
@export var _sprite_rotation: float = 0.0
## Path to this bullet's scene.
@export var _bullet_scene := ""

## Current remaining number of enemies this bullet can hit before it is destroyed.
var _bounces: int
## How many extra bullets are created at most when this bullet hits something.
var _splits: int = 0
## Enemy that this bullet is moving towards.
var _target: Node = null
## Node that this bullet last hit.
var _last_hit: Node = null
## True when we need to update this bullet's target next physics frame.
var _update_target: bool = false



func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _target != null:
		var target_direction = (_target.global_position - global_position).normalized()
		global_position += target_direction * speed * delta
		sprite.rotation = target_direction.angle() + deg_to_rad(_sprite_rotation)
	else:
		_find_new_target()


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
	# The squared distances of the nearest nodes in increasing order.
	var distances: Array[float] = [] 
	# The nearest nodes in increasing distance.
	var nodes: Array[Node2D] = []
	
	if !enemies.is_empty():
		# Find the n nearest enemies, where n = _splits + 1
		# This bullet will target the nearest enemy.
		# Nearest enemies after the first will have a new bullet be created for them.
		var n: int = _splits + 1
		
		for i in range(n):
			distances.append(INF)
			nodes.append(null)
		
		for enemy_area: Area2D in enemies:
			var enemy: Node = enemy_area.get_parent()
			if enemy == _target:
				continue
			if enemy is Enemy:
				var distance = global_position.distance_squared_to(enemy.global_position)
				
				# Insert the new enemy in sorted order into our lists of enemies and distances.
				for i in range(n):
					if distance < distances[i]:
						distances.insert(i, distance)
						nodes.insert(i, enemy)
						distances.pop_back()
						nodes.pop_back()
						break
		
		_last_hit = _target
		_target = nodes[0]
		# Server create a new Bounce bullet for each split.
		if is_multiplayer_authority():
			for i: int in range(1, n):
				if nodes[i] != null:
					GameState.playground.bullet_spawner.request_spawn_bullet.call_deferred(
						[
							_bullet_scene, 
							global_position, 
							Vector2.UP, 
							collider.damage, 
							collider.is_crit,
							_is_owned_by_player,
							collider.owner_id,
							collider.powerup_index,
							[
								nodes[i].get_path(), 
								_bounces,
								_splits,
								_target.get_path()
							]
						]
					)
				else:
					break
	
	# There were no valid enemies within range, so destroy this bullet.
	if _target == null and is_multiplayer_authority():
		queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 4
		or typeof(data[0]) != TYPE_NODE_PATH	# Path to first target
		or typeof(data[1]) != TYPE_INT			# Max number of bounces
		or typeof(data[2]) != TYPE_INT			# Max number of splits
		or typeof(data[3]) != TYPE_NODE_PATH	# Path to node last hit
	):
		push_error("Malformed data array")
		return
	
	_target = get_tree().root.get_node_or_null(data[0])
	_bounces = data[1]
	_splits = data[2]
	_last_hit = get_tree().root.get_node_or_null(data[3])
	_is_owned_by_player = is_owned_by_player
	if not is_owned_by_player:
		push_warning("Not implemented for enemies.")
		return


## Deal damage to overlapping Enemies. Bounce and split if the hit Enemy is the current target.
func _on_hitbox_area_2d_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	
	# Do not damage the Enemy that the bullet previously hit.
	if other != _last_hit and (other is Enemy or other is LootBox):
		if is_multiplayer_authority():
			other.take_damage(collider.damage)
		if other == _target:
			_find_new_target()
