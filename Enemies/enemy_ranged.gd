extends Enemy

# At most how far the enemy can be from the player before trying to shoot at them.
@export var max_range: float
@export var bullet_damage: float = 10.0
# Time in seconds between shots.
@export var fire_interval: float = 1.0
@export var bullet_scene: PackedScene

# Used for faster distance calculation
var squared_max_range: float
var fire_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	squared_max_range = max_range * max_range
	
	if ResourceLoader.exists(bullet_scene.to_string()):
		load(bullet_scene.to_string())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fire_timer < fire_interval:
		fire_timer += delta
	
	if target != null:
		if global_position.distance_squared_to(target.global_position) > squared_max_range:
			global_position = global_position.move_toward(target.global_position, delta*speed)
		else:
			# Shoot at the target
			if is_multiplayer_authority() and fire_timer >= fire_interval:
				var bullet = bullet_scene.instantiate()
				var direction = target.global_position - self.global_position
				var direction_normal = direction.normalized()
				bullet.set_damage(bullet_damage)
				bullet.direction = direction_normal
				bullet.position = self.global_position + (direction_normal * 100)
				get_node("..").add_child(bullet, true)
				fire_timer = 0.0
	else:
		_find_new_target()
