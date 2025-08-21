class_name BulletLightningArc
extends Bullet


## The maximum range which this arc will seek another Enemy to bounce to.
@export var _max_bounce_range: float = 500.0
## Time until this arc bounces to another enemy.
@export var _bounce_delay: float = 0.1
## Contains the visuals and collision for the bullet.
@export var _lightning: Node2D = null
## Bullet collision area.
@export var _area: Area2D = null
## Bullet collision shape.
@export var _collision_shape: CollisionShape2D = null

## Original collision layer
var _collision_layer: int = 0
## Original collision mask
var _collision_mask: int = 0
## Original sprite color
var _sprite_modulate: Color = Color.WHITE
## Animation tween for this bullet.
var _fade_out_tween: Tween = null
## The current range of this bounce.
var _bounce_range: float = 0.0
## Number of bounces remaining after this arc.
var _bounces: int = 0
var _is_level_three: bool = false
## Enemy that this arc comes from.
var _origin_enemy: Node = null
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
## True after the one frame that this bullet lasts for.
var _processed: bool = false
var _freed_area: bool = false


func _ready() -> void:
	hide()
	
	_collision_layer = _area.collision_layer
	_collision_mask = _area.collision_mask
	_area.collision_layer = 0
	_area.collision_mask = 0
	_sprite_modulate = sprite.modulate
	
	# Only physics process will be started when this bullet is active.
	set_physics_process(false)
	set_process(false)


func _process(_delta: float) -> void:
	# This is intentionally blank. It overrides Bullet's _process() function.
	pass


func _physics_process(delta: float) -> void:
	death_timer += delta
	if death_timer >= _bounce_delay:
		if not _processed:
			# Bounce to the next nearest Enemy.
			_processed = true
			sprite.flip_h = true
			
			var next_bounce: Node2D = null
			var nearest_distance_squared: float = INF
			
			if _bounces > 0:
				var space_state = get_world_2d().direct_space_state
				var bounce_query_params := PhysicsShapeQueryParameters2D.new()
				var circle_shape: CircleShape2D = CircleShape2D.new()
				
				bounce_query_params.collide_with_areas = true
				bounce_query_params.collide_with_bodies = false
				# The 2nd layer/1st bit is the "enemy" collision layer
				bounce_query_params.collision_mask = 1 << 1
				circle_shape.radius = _bounce_range
				bounce_query_params.shape = circle_shape
				bounce_query_params.transform = Transform2D(0.0, global_position)
				
				var nearby_enemies: Array[Dictionary] = space_state.intersect_shape(bounce_query_params)
				for hit: Dictionary in nearby_enemies:
					var hit_enemy: Node = hit["collider"].get_parent()
					if hit_enemy != _origin_enemy and hit_enemy is Enemy:
						var dist: float = hit_enemy.global_position.distance_squared_to(global_position)
						if dist < nearest_distance_squared:
							nearest_distance_squared = dist
							next_bounce = hit_enemy
			
			if next_bounce != null:
				# There is a valid next bounce target, so stretch this arc towards it and create a new 
				# arc from that enemy.
				var rotation_direction: Vector2 = next_bounce.global_position - global_position
				global_position += rotation_direction / 2
				rotation = rotation_direction.angle()
				var length_of_lightning = _collision_shape.shape.size.x
				_lightning.scale.x = rotation_direction.length() / length_of_lightning
				
				sprite.flip_h = false
				show()
				
				# Only the server will create the next bullet bounce.
				if is_multiplayer_authority():
					var crit: bool = randf() < _crit_chance
					var total_damage: float = collider.damage * (1.0 if not crit else _crit_multiplier)
					_area.collision_layer = _collision_layer
					_area.collision_mask = _collision_mask
					
					GameState.playground.create_lightning_arc.rpc(
						next_bounce.global_position, 
						total_damage, 
						crit,
						_is_owned_by_player,
						collider.owner_id,
						collider.powerup_index,
						[
							_bounces - 1, 
							_is_level_three, 
							sqrt(nearest_distance_squared), 
							next_bounce.get_path(),
							_crit_chance,
							_crit_multiplier
						]
					)
			else:
				# No next valid bounce target
				_lightning.scale.x = 0.0
		else:
			# One frame after the bounce, turn off collision.
			_freed_area = true
			_area.collision_layer = 0
			_area.collision_mask = 0
			set_physics_process(false)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 6
		or typeof(data[0]) != TYPE_INT			# Number of bounces remaining
		or typeof(data[1]) != TYPE_BOOL			# Has level 3 upgrade or not
		or typeof(data[2]) != TYPE_FLOAT		# Max range. -1 if the range is not limited.
		or typeof(data[3]) != TYPE_NODE_PATH	# Node this lightning is originating from
		or typeof(data[4]) != TYPE_FLOAT		# Crit chance
		or typeof(data[5]) != TYPE_FLOAT		# Crit multiplier
	):
		push_error("Malformed data array")
		return
	
	_bounces = data[0]
	_is_level_three = data[1]
	if data[2] >= 0.0:
		_bounce_range = data[2]
	else:
		_bounce_range = _max_bounce_range
	_origin_enemy = get_node(data[3])
	_crit_chance = data[4]
	_crit_multiplier = data[5]
	_is_owned_by_player = is_owned_by_player
	
	# Play fading out animation
	sprite.modulate = _sprite_modulate
	if _fade_out_tween != null:
		_fade_out_tween.kill()
	_fade_out_tween = create_tween()
	_fade_out_tween.set_ease(Tween.EASE_OUT)
	_fade_out_tween.set_trans(Tween.TRANS_QUINT)
	_fade_out_tween.tween_property(sprite, "modulate", Color.html("ffffff00"), 0.5)
	
	death_timer = 0.0
	_processed = false
	_freed_area = false
	set_physics_process(true)


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass
