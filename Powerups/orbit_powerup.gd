class_name PowerupOrbit
extends Powerup

var bullet_scene := "res://Powerups/orbit_bullet.tscn"
var sprite = preload("res://Coconut.png")
## The instantiated bullets controlled by this powerup. Orbit bullets register themselves
## with this powerup after they spawn.
var _bullets: Array[BulletOrbit] = [] 

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float) 


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_crit_multiplier(new_multiplier: float) -> void:
	super(new_multiplier)
	crit_changed.emit(crit_chance, crit_multiplier)


## Add a reference to an instantated bullet.
func add_bullet(bullet: Bullet) -> void:
	_bullets.append(bullet)


func _ready() -> void:
	super()


func activate_powerup():
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.RIGHT, 
				_get_damage_from_curve(), 
				false,
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
					false,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[multiplayer.get_unique_id()]
				]
			)
		
		if _area_size_boosted:
			boost_area_size()
	else:
		push_error("Not implemented")


func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	
	# Level 3 special: Two bullets at opposite ends
	if current_level == 3:
		for bullet: Bullet in _bullets:
			bullet.queue_free()
		_bullets.clear()
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.RIGHT, 
				_get_damage_from_curve(), 
				false,
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
				false,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[multiplayer.get_unique_id()]
			]
		)
	
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	for bullet: BulletOrbit in _bullets:
		if bullet != null:
			bullet.boost.rpc()


func unboost() -> void:
	for bullet: BulletOrbit in _bullets:
		if bullet != null:
			bullet.unboost.rpc()


func boost_haste() -> void:
	for bullet: BulletOrbit in _bullets:
		if bullet != null:
			bullet.boost.rpc()


func boost_area_size() -> void:
	super()
	for bullet: BulletOrbit in _bullets:
		if bullet != null:
			bullet.boost_area_size.rpc()
