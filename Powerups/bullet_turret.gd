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
## Properties for analytics
var _owner_id: int = -1
var _powerup_index: int = -1
## Whether or not the turret is going through the removal animation
var _is_being_removed: bool = false


func _ready() -> void:
	## Animate spawning in
	var full_scale = _turret_sprite.scale
	_turret_sprite.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_turret_sprite, "scale", full_scale, 0.5)
	
	if not is_multiplayer_authority():
		set_process(false)


## Only server processes Turret.
func _process(delta: float) -> void:
	_fire_timer += delta
	if _fire_timer >= _fire_interval:
		_shoot()
		_fire_timer = 0.0
	
	death_timer += delta
	if death_timer >= lifetime and !_is_being_removed:
		_is_being_removed = true
		## Play removing animation
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(_turret_sprite, "scale", Vector2.ZERO, 0.5)
		# Remove after animation finishes
		tween.tween_callback(queue_free)


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
	var target_position: Vector2 = _find_nearest_target_position()
	
	# Only shoot if there is something within range to shoot at.
	if target_position != global_position:
		get_tree().root.get_node("Playground/BulletSpawner").spawn(
			[
				_turret_bullet_scene, 
				global_position, 
				(target_position - global_position).normalized(), 
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
