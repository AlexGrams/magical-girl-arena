extends Node2D

@export var speed = 5
@export var lifetime = 1
var direction:Vector2
var player:Node2D
var closest_enemy
var return_timer = 0
var is_returning = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_returning:
		# Move towards player
		global_position += (player.global_position - global_position).normalized() * speed
		
		# If close enough to player, send out again
		if (player.global_position - global_position).length() <= 2:
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
			
			is_returning = false
			return_timer = 0
	else:
		if closest_enemy != null:
			global_position += (closest_enemy.global_position - global_position).normalized() * speed
		else:
			is_returning = true
		
		if return_timer >= lifetime:
			return_timer = 0
			is_returning = true
		
		return_timer += delta
