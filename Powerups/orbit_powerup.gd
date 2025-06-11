class_name PowerupOrbit
extends Powerup

var bullet_scene := "res://Powerups/orbit_bullet.tscn"
var sprite = preload("res://Coconut.png")
## The instantiated bullets controlled by this powerup. Orbit bullets register themselves
## with this powerup after they spawn.
var _bullets: Array[Bullet] = [] 

signal picked_up_powerup(sprite)


## Add a reference to an instantated bullet.
func add_bullet(bullet: Bullet) -> void:
	_bullets.append(bullet)


func _ready() -> void:
	pass


func activate_powerup():
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.RIGHT, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[multiplayer.get_unique_id()]
			]
		)
		
		if current_level >= 3:
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1,
				[
					bullet_scene, 
					Vector2.ZERO, 
					Vector2.LEFT, 
					_get_damage_from_curve(), 
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[multiplayer.get_unique_id()]
				]
			)
	else:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				-1,
				-1,
				[get_parent().get_path()]
			]
		)
	
	picked_up_powerup.emit(sprite)


func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	
	# Level 3 special: Two bullets at opposite ends
	if current_level == 3:
		for bullet: Bullet in _bullets:
			bullet.queue_free()
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.RIGHT, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[multiplayer.get_unique_id()]
			]
		)
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.LEFT, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[multiplayer.get_unique_id()]
			]
		)
		
	
	powerup_level_up.emit(current_level, _get_damage_from_curve())
