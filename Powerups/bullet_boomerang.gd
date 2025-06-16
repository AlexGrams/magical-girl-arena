class_name  BulletBoomerang
extends Bullet

## How close the Boomerang needs to get to its destination before switching directions.
const touching_distance_threshold: float = 30.0

## Target enemy must be within this range
@export var max_range: float = 750

## The bullet object is replicated on all clients.
## This owner is the client's replicated version of the character that owns this bullet.
var boomerang_owner: Node2D = null
var farthest_enemy: Node
var is_returning := true

@onready var _squared_touching_distance_threshold: float = touching_distance_threshold ** 2
## When owned by an Enemy, the location that the bullet to moving towards away from its owner. 
var _target_location := Vector2.ZERO


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if is_returning:
		if boomerang_owner == null or boomerang_owner.is_queued_for_deletion():
			return
		
		# Move towards player
		global_position += (boomerang_owner.global_position - global_position).normalized() * speed * delta
		
		# If close enough to player, send out again
		if boomerang_owner.global_position.distance_squared_to(global_position) <= _squared_touching_distance_threshold:
			# Get next nearest character to attack
			var enemies: Array[Node] = [] 
			if _is_owned_by_player:
				enemies = get_tree().get_nodes_in_group("enemy")
			else:
				enemies = get_tree().get_nodes_in_group("player")
				
			if !enemies.is_empty():
				farthest_enemy = null
				var farthest_distance = 0
				for enemy in enemies:
					var distance = global_position.distance_squared_to(enemy.global_position)
					if distance > farthest_distance and distance <= (max_range * max_range):
						farthest_enemy = enemy
						farthest_distance = distance
			
			# An Enemy Boomerang moves towards a static location instead of chasing the Player.
			if not _is_owned_by_player:
				_target_location = farthest_enemy.global_position
			
			# Stop returning and start moving out
			is_returning = false
	else:
		if _is_owned_by_player:
			# If the closest enemy still exists, move towards them
			# Otherwise return to player
			if farthest_enemy != null:
				global_position += (farthest_enemy.global_position - global_position).normalized() * speed * delta
				if farthest_enemy.global_position.distance_squared_to(global_position) <= _squared_touching_distance_threshold:
					is_returning = true
			else:
				is_returning = true
		else:
			# Enemy Boomerang behavior
			global_position += (_target_location - global_position).normalized() * speed * delta
			if (_target_location - global_position).length() <= touching_distance_threshold:
				is_returning = true


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning character 
	):
		return
	
	boomerang_owner = get_tree().root.get_node(data[0])
	
	_is_owned_by_player = is_owned_by_player
	if is_owned_by_player:
		# When the player levels up this powerup, notify all clients about the level up.
		var boomerang_powerup := boomerang_owner.get_node_or_null("BoomerangPowerup")
		# The Powerup child is not replicated, so only the client which owns this character has it.
		if boomerang_powerup != null:
			boomerang_powerup.powerup_level_up.connect(func(new_level: int, new_damage: float):
				level_up.rpc(new_level, new_damage)
			)
	
		# When the owner goes down, destroy this bullet
		boomerang_owner.died.connect(func():
			queue_free()
		)
	else:
		_modify_collider_to_harm_players()
		
		# Destroy bullet when owning Enemy dies
		if is_multiplayer_authority():
			boomerang_owner.died.connect(func(_enemy: Enemy):
				queue_free()
			)


func set_damage(damage:float):
	$Area2D.damage = damage


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(new_level: int, new_damage: float):
	$Area2D.damage = new_damage
	if new_level == 3:
		# Increase size
		scale = scale * 2
