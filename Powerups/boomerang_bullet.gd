extends Bullet

# The bullet object is replicated on all clients.
# This player is the client's replicated version of the character that owns this bullet.
# This is not necessarily the client's own character.
var player: Node2D

var closest_enemy: Node
var is_returning := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_returning:
		# Move towards player
		global_position += (player.global_position - global_position).normalized() * speed * delta
		
		# If close enough to player, send out again
		if (player.global_position - global_position).length() <= 30:
			# Get next nearest enemy to attack
			var enemies = get_tree().get_nodes_in_group("enemy")
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
func setup_bullet(data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning player 
	):
		return
	
	player = get_tree().root.get_node(data[0])
	
	# When the player levels up this powerup, notify all clients about the level up.
	var boomerang_powerup := player.get_node_or_null("BoomerangPowerup")
	# The Powerup child is not replicated, so only the client which owns this character has it.
	if boomerang_powerup != null:
		boomerang_powerup.powerup_level_up.connect(func(new_level: int, new_damage: float):
			level_up.rpc(new_level, new_damage)
		)


func set_damage(damage:float):
	$Area2D.damage = damage


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	$Area2D.damage = new_damage
