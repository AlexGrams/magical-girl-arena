extends Powerup

## Time in seconds between creating bullets.
@export var shoot_interval = 1.0
## UID to the Bullet-derived bullet scene.
@export var bullet_scene := ""

var _shoot_timer: float = 0.0
var _bullet_spawner: BulletSpawner = null


func _ready() -> void:
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		if _is_owned_by_player:
			# Get nearest enemy so direction can be set
			var enemies: Array[Node] = [] 
			enemies = get_tree().get_nodes_in_group("enemy")
			
			if !enemies.is_empty():
				var nearest_enemy = enemies[0]
				var nearest_distance = global_position.distance_squared_to(enemies[0].global_position)
				for enemy in enemies:
					var distance = global_position.distance_squared_to(enemy.global_position)
					if distance < nearest_distance:
						nearest_enemy = enemy
						nearest_distance = distance
			
				var direction = (nearest_enemy.global_position - self.global_position).normalized()
				_bullet_spawner.request_spawn_bullet.rpc_id(
					1,
					[
						bullet_scene, 
						global_position, 
						direction, 
						_get_damage_from_curve(), 
						_is_owned_by_player,
						multiplayer.get_unique_id(),
						_powerup_index,
						[multiplayer.get_unique_id(), is_signature and current_level == max_level]
					]
				)
		else:
			var owning_enemy: Node2D = get_parent()
			
			if (owning_enemy != null 
				and not owning_enemy.is_queued_for_deletion() 
				and owning_enemy.target != null
			):
				var direction = owning_enemy.target.global_position - self.global_position
				direction = direction.normalized()
				
				_bullet_spawner.request_spawn_bullet.rpc_id(
					1, 
					[
						bullet_scene, 
						global_position, 
						direction, 
						owning_enemy.attack_damage, 
						_is_owned_by_player,
						-1,
						-1,
						[owning_enemy.get_path()]
					]
				)
		
		_shoot_timer = 0


func activate_powerup():
	is_on = true


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
