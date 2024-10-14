extends Node2D

@export var speed = 800
var direction:Vector2
var player:Node2D
var closest_enemy
var is_returning = true

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

func set_damage(damage:float):
	$Area2D.damage = damage
