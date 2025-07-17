extends Bullet


## The maximum range which this arc will seek another Enemy to bounce to.
@export var _max_bounce_range: float = 500.0
## Contains the visuals and collision for the bullet.
@export var _lightning: Node2D = null
## Bullet collision area.
@export var _area: Area2D = null
## Bullet collision shape.
@export var _collision_shape: CollisionShape2D = null
@export var _lightning_arc_scene: String = ""

## Number of bounces remaining after this arc.
var _bounces: int = 0
var _is_level_three: bool = false
## Enemy that this arc comes from.
var _origin_enemy: Node = null
## True after the one frame that this bullet lasts for.
var _processed: bool = false
var _freed_area: bool = false


func _ready() -> void:
	# Play fading out animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(sprite, "modulate", Color.html("ffffff00"), 0.5)


func _process(_delta: float) -> void:
	# This is intentionally blank. It overrides Bullet's _process() function.
	pass


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
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
			circle_shape.radius = _max_bounce_range
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
			
			get_tree().root.get_node("Playground/BulletSpawner").call_deferred("request_spawn_bullet",
				[
					_lightning_arc_scene, 
					next_bounce.global_position, 
					Vector2.UP, 
					collider.damage, 
					_is_owned_by_player,
					collider.owner_id,
					collider.powerup_index,
					[_bounces - 1, _is_level_three, sqrt(nearest_distance_squared), next_bounce.get_path()]
				]
			)
		else:
			# No next valid bounce target
			_lightning.scale.x = 0.0
	elif not _freed_area:
		# Only delete the collision, but let the lightning fade out
		_freed_area = true
		_area.queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 4
		or (typeof(data[0])) != TYPE_INT		# Number of bounces remaining
		or (typeof(data[1])) != TYPE_BOOL		# Has level 3 upgrade or not
		or (typeof(data[2])) != TYPE_FLOAT		# Max range. -1 if the range is not limited.
		or (typeof(data[3])) != TYPE_NODE_PATH	# Node this lightning is originating from
	):
		push_error("Malformed data array")
		return
	
	_bounces = data[0]
	_is_level_three = data[1]
	if data[2] >= 0.0:
		_max_bounce_range = data[2]
	_origin_enemy = get_node(data[3])
	_is_owned_by_player = is_owned_by_player
