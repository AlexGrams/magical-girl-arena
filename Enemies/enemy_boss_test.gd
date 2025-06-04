extends EnemyBoss


## Squared distance for which the boss is considered to be at one of its movement points.
const _squared_destination_theshold: float = 100.0

## Time in seconds between when the boss switches which attack pattern its doing.
@export var _pattern_interval: float = 5.0
## The distance of the points that the boss moves between from its spawn position
@export var _movement_radius: float = 500.0
## Multiplier by which to increase boss health by depending on the number of players in the game.
@export var _health_scale: Array[float] = [1.0, 1.0, 1.0, 1.0]
## UIDs of Powerup scenes to add to the boss.
@export var powerups_to_add: Array[String] = []

## Time in seconds until the next pattern switch.
var _pattern_switch_timer: float = 0.0
## Which attack pattern the boss is currently doing.
var _pattern_index: int = 0
## The five points of the star that the boss moves between as its regular movement pattern.
var _movement_points: Array[Vector2] = []
var _current_movement_point: int = 0


func _ready() -> void:
	super()
	
	# Scale health for number of players. Overrides how base Enemy scales health.
	max_health = base_health * _health_scale[GameState.connected_players - 1]
	health = max_health
	
	if not is_multiplayer_authority():
		set_process(false)
		return
	
	for powerup_uid: String in powerups_to_add:
		var powerup: PackedScene = load(powerup_uid)
		if powerup != null:
			_add_powerup(powerup)
	for powerup: Powerup in _powerups:
		powerup.deactivate_powerup()


# Only process on the server.
func _process(delta: float) -> void:
	_pattern_switch_timer -= delta
	if _pattern_switch_timer <= 0:
		# Choose a random new attack pattern
		_powerups[_pattern_index].deactivate_powerup()
		
		var new_pattern_choices: Array[int] = []
		for i in range(len(_powerups)):
			if i != _pattern_index:
				new_pattern_choices.append(i)
		_pattern_index = new_pattern_choices.pick_random()
		_powerups[_pattern_index].activate_powerup()
		
		_pattern_switch_timer = _pattern_interval


func _physics_process(_delta: float) -> void:
	if target != null:
		if global_position.distance_squared_to(_movement_points[_current_movement_point]) <= _squared_destination_theshold:
			# Boss has completed one movement, so find the next point to move towards.
			_current_movement_point = (_current_movement_point + 2) % 5
		
		velocity = (_movement_points[_current_movement_point] - global_position).normalized() * speed
		move_and_slide()
	else:
		if is_multiplayer_authority():
			_find_new_target()
		else:
			move_and_slide()


## Move this enemy to a location.
@rpc("authority", "call_local")
func teleport(pos: Vector2) -> void:
	global_position = pos
	
	# Calculate the five points of the star that the boss moves between after it is teleported to its
	# starting position.
	if len(_movement_points) == 0:
		var direction := Vector2.UP * _movement_radius
		for i in range(5):
			_movement_points.append(direction + global_position)
			direction = direction.rotated(deg_to_rad(72.0))
