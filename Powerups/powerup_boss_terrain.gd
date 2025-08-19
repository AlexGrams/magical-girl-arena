extends Powerup
## Produces high-damage attacks around the map which persist as terrain elements.


const DEG_TO_RAD: float = PI / 180.0

## Attack damage.
@export var _damage: float = 100.0
## How many bullets are created by this attack. The bigger this number is, the more likely
## it is for attacks to overlap.
@export var _attacks: int = 4
## Minimum distance that an attack spawns from the owning boss.
@export var _min_distance: float = 750.0
## Maximum distance that an attack spawns from the owning boss.
@export var _max_distance: float = 1500.0
## The farthest angular displacement that an attack can spawn in each spawn section. The
## bigger this number is, the more likely it is for attacks to overlap.
@export var _max_angle_variance_degrees: float = 30.0
@export var _bullet_scene := ""


func _ready() -> void:
	_is_owned_by_player = false


func activate_powerup():
	var spawn_section_direction: Vector2 = Vector2.RIGHT
	
	# The places where an attack could spawn are divided into sections, or "slices" of a circle
	# To try to prevent attacks from spawning too close to each other, they are only allowed to
	# spawn in a limited slice of each section. The size of each slice is 
	# 2 * _max_angle_variance_degrees. 
	for i in range(_attacks):
		var spawn_direction: Vector2 = spawn_section_direction.rotated(
				DEG_TO_RAD * randf_range(-_max_angle_variance_degrees, _max_angle_variance_degrees))
		GameState.playground.get_node("BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				_bullet_scene, 
				global_position + spawn_direction * randf_range(_min_distance, _max_distance), 
				spawn_direction * -1.0, 
				_damage, 
				false,
				_is_owned_by_player,
				-1,
				-1,
				[]
			]
		)
		
		spawn_section_direction = spawn_section_direction.rotated(2 * PI / _attacks)


func deactivate_powerup():
	pass
