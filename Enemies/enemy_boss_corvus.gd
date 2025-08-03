extends EnemyBoss


## Squared distance for which the boss is considered to be at one of its movement points.
const _squared_destination_theshold: float = 100.0

## Time in seconds between when the boss switches which attack pattern its doing.
@export var _pattern_interval: float = 5.0
## The distance of the points that the boss moves between from its spawn position
@export var _movement_radius: float = 500.0
## When the boss is at this fraction of its max health, switch to phase 2.
@export var _phase_two_health_fraction: float = 0.15
## Paths to Powerup scenes for the boss's phase one attacks.
@export var _powerup_paths_phase_one: Array[String] = []
## Paths to Powerup scenes for the boss's phase two attacks.
@export var _powerup_paths_phase_two: Array[String] = []

## Phase one powerups
var _powerups_one: Array[Powerup]
## Phase two powerups 
var _powerups_two: Array[Powerup]
## Time in seconds until the next pattern switch.
var _pattern_switch_timer: float = 0.0
## Which attack pattern the boss is currently doing.
var _current_attack: Powerup = null
## The five points of the star that the boss moves between as its regular movement pattern.
var _movement_points: Array[Vector2] = []
var _current_movement_point: int = 0


func _ready() -> void:
	super()
	
	# Scale health for number of players. Overrides how base Enemy scales health.
	max_health = int(base_health * _health_scale[GameState.connected_players - 1])
	health = max_health
	
	if not is_multiplayer_authority():
		set_process(false)
		return
	
	# Instantiating phase one powerups
	for powerup_path: String in _powerup_paths_phase_one:
		var powerup: PackedScene = load(powerup_path)
		if powerup != null:
			_add_powerup(powerup)
			_powerups_one.append(_powerups[-1])
	# Instantiating phase two powerups
	for powerup_path: String in _powerup_paths_phase_two:
		var powerup: PackedScene = load(powerup_path)
		if powerup != null:
			_add_powerup(powerup)
			_powerups_two.append(_powerups[-1])
	
	for powerup: Powerup in _powerups:
		powerup.deactivate_powerup()


# Only process on the server.
func _process(delta: float) -> void:
	_pattern_switch_timer -= delta
	if _pattern_switch_timer <= 0:
		# Choose a random new attack pattern
		if _current_attack != null:
			_current_attack.deactivate_powerup()
		
		var new_attack_choices: Array[Powerup] = []
		if float(health) / max_health > _phase_two_health_fraction:
			for powerup: Powerup in _powerups_one:
				if powerup != _current_attack:
					new_attack_choices.append(powerup)
		else:
			for powerup: Powerup in _powerups_two:
				if powerup != _current_attack:
					new_attack_choices.append(powerup)
		
		if len(new_attack_choices) > 0:
			_current_attack = new_attack_choices.pick_random()
			_current_attack.activate_powerup()
		else:
			_current_attack = null
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
	
	# Continuous damage 
	if is_multiplayer_authority() and _continuous_damage > 0.0:
		_take_damage(_continuous_damage)


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
