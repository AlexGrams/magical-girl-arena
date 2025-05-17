extends Powerup
## Shoots many small bullets in a cone towards the nearest enemy.

@export var shoot_interval: float = 1.0
@export var bullet_damage: float = 50.0
@export var _bullet_uid := "res://Powerups/bullet.tscn"
## How many bullets are made per firing
@export var _num_bullets: int = 10
## Angle in degrees for which bullets are evenly spread towards the target.
## Bullets are angled at most _fire_angle/2 degrees away from the target.
@export var _fire_angle: float = 60.0

var shoot_timer: float = 0
## Angle in radians of far apart each bullet is spread.
var _fire_angle_rad_delta: float = 0

signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bullet_damage = _get_damage_from_curve()
	_fire_angle_rad_delta = deg_to_rad(_fire_angle / _num_bullets)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		var direction := Vector2.ZERO
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
			
				direction = (nearest_enemy.global_position - self.global_position).normalized()
		else:
			# Enemy bullet moves in direction of Enemy's desired velocity.
			direction = get_parent().velocity.normalized()
		direction = direction.rotated(deg_to_rad(-_fire_angle / 2.0))
		
		for i in range(_num_bullets):
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1, [_bullet_uid, 
					global_position, 
					direction, 
					bullet_damage, 
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[]
				]
			)
			direction = direction.rotated(_fire_angle_rad_delta)
		
		shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit()


func deactivate_powerup():
	is_on = false
	shoot_timer = 0.0


func level_up():
	current_level += 1
	bullet_damage = _get_damage_from_curve()
	powerup_level_up.emit(current_level, bullet_damage)
