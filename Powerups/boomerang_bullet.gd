extends Bullet

# The bullet object is replicated on all clients.
# This owner is the client's replicated version of the character that owns this bullet.
var boomerang_owner: Node2D = null

var closest_enemy: Node
var is_returning := true
var _is_owned_by_player := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_returning:
		if boomerang_owner == null or boomerang_owner.is_queued_for_deletion():
			return
		
		# Move towards player
		global_position += (boomerang_owner.global_position - global_position).normalized() * speed * delta
		
		# If close enough to player, send out again
		if (boomerang_owner.global_position - global_position).length() <= 30:
			# Get next nearest enemy to attack
			var enemies: Array[Node] = [] 
			if _is_owned_by_player:
				enemies = get_tree().get_nodes_in_group("enemy")
			else:
				enemies = get_tree().get_nodes_in_group("player")
				
			if !enemies.is_empty():
				closest_enemy = enemies[0]
				var closest_distance = global_position.distance_squared_to(enemies[0].global_position)
				for enemy in enemies:
					var distance = global_position.distance_squared_to(enemy.global_position)
					if distance < closest_distance:
						closest_enemy = enemy
						closest_distance = distance
			
			# Stop returning and start moving out
			is_returning = false
	else:
		# If the closest enemy still exists, move towards them
		# Otherwise return to player
		if closest_enemy != null:
			global_position += (closest_enemy.global_position - global_position).normalized() * speed * delta
			if (closest_enemy.global_position - global_position).length() <= 30:
				is_returning = true
		else:
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
	else:
		_modify_collider_to_harm_players()
	
	# When the owner goes down, destroy this bullet
	boomerang_owner.died.connect(func():
		queue_free()
	)


func set_damage(damage:float):
	$Area2D.damage = damage


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	$Area2D.damage = new_damage
