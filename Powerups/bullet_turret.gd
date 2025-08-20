extends Bullet
## Shoots bullets at nearby enemies. Doesn't do damage directly. 


## The actual bullet that does damage for the Boomerang powerup.
@export var _turret_bullet_scene: String = ""
## Used to get possible targets within range.
@export var _range_area: Area2D = null
## Turret sprite
@export var _turret_sprite: Sprite2D = null

## Time in seconds between when this Turret shoots.
var _fire_interval: float = 0.0
## Time until next firing.
var _fire_timer: float = 0.0
## How much damage each boomerang does
var _damage: float = 0.0
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
## Time remaining for this turret's boost.
var _boost_timer: float = 0.0
## Properties for analytics
var _owner_id: int = -1
var _powerup_index: int = -1
## Whether or not the turret is going through the removal animation
var _is_being_removed: bool = false


func _ready() -> void:
	add_to_group("bullet_turret")
	## Animate spawning in
	var full_scale = _turret_sprite.scale
	_turret_sprite.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_turret_sprite, "scale", full_scale, 0.5)


## Only server processes Turret.
func _process(delta: float) -> void:
	# Boost 
	if _boost_timer > 0.0:
		_boost_timer -= delta
		if _boost_timer <= 0.0:
			_shrink()
	
	# Shooting
	if is_multiplayer_authority():
		_fire_timer += delta
		if _fire_timer >= _fire_interval:
			_shoot()
			_fire_timer = 0.0
	
	# Removal
	death_timer += delta
	if death_timer >= lifetime and !_is_being_removed:
		_is_being_removed = true
		## Play removing animation
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(_turret_sprite, "scale", Vector2.ZERO, 0.5)
		# Remove after animation finishes
		if is_multiplayer_authority():
			tween.tween_callback(queue_free)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 5
		or typeof(data[0]) != TYPE_FLOAT	# Fire interval 
		or typeof(data[1]) != TYPE_FLOAT	# Lifetime
		or typeof(data[2]) != TYPE_FLOAT	# Starting boost duration
		or typeof(data[3]) != TYPE_FLOAT	# Crit chance
		or typeof(data[4]) != TYPE_FLOAT	# Crit multiplier
	):
		push_error("Malformed data array")
		return
	
	
	_fire_interval = data[0]
	lifetime = data[1]
	_crit_chance = data[3]
	_crit_multiplier = data[4]
	_is_owned_by_player = is_owned_by_player
	
	# Boost given to the turret when it spawns.
	if data[2] > 0.0:
		boost(data[2])


func set_damage(damage:float, _is_crit: bool = false):
	_damage = damage


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	_owner_id = owner_id
	_powerup_index = powerup_index
	
	if owner_id != multiplayer.get_unique_id():
		_update_bullet_opacity()


func _shoot() -> void:
	var target_position: Vector2 = _find_nearest_target_position()
	
	# Only shoot if there is something within range to shoot at.
	if target_position != global_position:
		var crit: bool = randf() < _crit_chance
		var total_damage: float = _damage * (1.0 if not crit else _crit_multiplier)
		get_tree().root.get_node("Playground/BulletSpawner").spawn(
			[
				_turret_bullet_scene, 
				global_position, 
				(target_position - global_position).normalized(), 
				total_damage, 
				crit,
				_is_owned_by_player,
				_owner_id,
				_powerup_index,
				[_boost_timer > 0.0]
			]
		)


## Returns location of the nearest target.
func _find_nearest_target_position() -> Vector2: 
	if _is_owned_by_player:
		var nearest_position: Vector2 = global_position
		var least_health = INF
		
		for area: Area2D in _range_area.get_overlapping_areas():
			if area.get_parent() is Enemy:
				if area.get_parent().health < least_health:
					nearest_position = area.global_position
					least_health = area.get_parent().health
		return nearest_position
	else:
		push_warning("Not implemented for enemies")
	return Vector2.UP


## Powers up this turret for a limited time.
func boost(duration: float) -> void:
	if _boost_timer > 0.0:
		# Extend boost duration if already boosted.
		if _boost_timer < duration:
			_boost_timer = duration
	else:
		_boost_timer = duration
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(self, "scale", scale * 2.0, 0.25)
		_fire_interval = _fire_interval * 0.8


## Shrinks in size if it was the level 3 upgrade
func _shrink() -> void:
	# Return bullet effects to normal
	_fire_interval = _fire_interval * 1.25
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", scale * 0.5, 0.25)
