class_name PowerupTether
extends Powerup


@export var bullet_scene := "res://Powerups/bullet_laser.tscn"
@export var max_range: float = 500

## Signals to the laser bullet to activate signature functionality if this powerup is signature and max level.
signal activate_piercing()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func activate_powerup():
	is_on = true
	
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[get_parent().get_path(), max_range, get_parent().get_path(), false]
			]
		)
	else:
		pass

func deactivate_powerup():
	is_on = false

func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if current_level == 3:
		activate_piercing.emit()
	if current_level == 5 and is_signature:
		# Add 2 extra lasers
		var laser_pos_1:Node2D = get_parent().get_node("LaserPos")
		var laser_pos_2:Node2D = get_parent().get_node("LaserPos2")
		laser_pos_1.show()
		laser_pos_2.show()
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[get_parent().get_path(), max_range, laser_pos_1.get_path(), true]
			]
		)
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[get_parent().get_path(), max_range, laser_pos_2.get_path(), true]
			]
		)
