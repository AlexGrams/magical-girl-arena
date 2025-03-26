class_name EnemyRanged
extends Enemy

# At most how far the enemy can be from the player before trying to shoot at them.
@export var max_range: float
@export var bullet_damage: float = 10.0
# Time in seconds between shots.
@export var fire_interval: float = 1.0
@export var bullet_scene_path: String = ""
@export var allied_bullet_scene_path := "res://Powerups/bullet.tscn"

# Used for faster distance calculation
var squared_max_range: float
var fire_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	squared_max_range = max_range * max_range


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fire_timer < fire_interval:
		fire_timer += delta
	
	# Allied lifetime check
	if is_ally:
		lifetime -= delta
		if lifetime <= 0.0:
			take_damage(health)


func _physics_process(_delta: float) -> void:
	if target != null:
		if global_position.distance_squared_to(target.global_position) > squared_max_range:
			velocity = (target.global_position - global_position).normalized() * speed
			move_and_slide()
		else:
			# Shoot at the target
			if is_multiplayer_authority() and fire_timer >= fire_interval:
				shoot()
				fire_timer = 0.0
	else:
		_find_new_target()


# Perform a ranged attack by spawning a bullet.
func shoot() -> void:
	var direction = target.global_position - self.global_position
	var direction_normal = direction.normalized()
	if not is_ally:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [bullet_scene_path, 
				self.global_position + (direction_normal * 100), 
				direction_normal, 
				bullet_damage, 
				false,
				[]
			]
		)
	else:
		# Alternate attack behavior for when this Enemy is an ally
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [allied_bullet_scene_path, 
				self.global_position + (direction_normal * 100), 
				direction_normal, 
				bullet_damage, 
				true,
				[]
			]
		)
