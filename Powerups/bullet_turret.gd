extends Bullet
## Shoots bullets at nearby enemies. Doesn't do damage directly. 


## The actual bullet that does damage for the Boomerang powerup.
@export var _turret_bullet_scene: String = ""

## Time in seconds between when this Turret shoots.
var _fire_interval: float = 0.0
## Time until next firing.
var _fire_timer: float = 0.0
## How much damage each boomerang does
var _damage: float = 0.0
## Properties for analytics
var _owner_id: int = -1
var _powerup_index: int = -1


func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)


## Only server processes Turret.
func _process(delta: float) -> void:
	_fire_timer += delta
	if _fire_timer >= _fire_interval:
		_shoot()
		_fire_timer = 0.0
	
	death_timer += delta
	if death_timer >= lifetime:
		queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or typeof(data[0]) != TYPE_FLOAT		# Fire interval 
		or typeof(data[1]) != TYPE_FLOAT 		# Lifetime
	):
		push_error("Malformed data array")
		return
	
	_fire_interval = data[0]
	lifetime = data[1]
	_is_owned_by_player = is_owned_by_player


func set_damage(damage:float):
	_damage = damage


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	_owner_id = owner_id
	_powerup_index = powerup_index


func _shoot() -> void:
	get_tree().root.get_node("Playground/BulletSpawner").spawn(
		[
			_turret_bullet_scene, 
			global_position, 
			(_find_nearest_target_position() - global_position).normalized(), 
			_damage, 
			_is_owned_by_player,
			_owner_id,
			_powerup_index,
			[]
		]
	)


## Returns location of the nearest target.
func _find_nearest_target_position() -> Vector2: 
	if _is_owned_by_player:
		# Get nearest enemy so direction can be set
		var enemies: Array[Node] = [] 
		enemies = get_tree().get_nodes_in_group("enemy")
		
		if !enemies.is_empty():
			var nearest_position: Vector2 = enemies[0].global_position
			var nearest_distance = global_position.distance_squared_to(enemies[0].global_position)
			for enemy in enemies:
				var distance = global_position.distance_squared_to(enemy.global_position)
				if distance < nearest_distance:
					nearest_position = enemy.global_position
					nearest_distance = distance
			return nearest_position
	else:
		push_warning("Not implemented for enemies")
	return Vector2.UP
