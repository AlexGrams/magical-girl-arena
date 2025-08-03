extends EnemyBoss


## Time in seconds between when the boss switches which attack pattern its doing.
@export var _pattern_interval: float = 5.0
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
	# TODO: Movement, if any
	
	# Continuous damage 
	if is_multiplayer_authority() and _continuous_damage > 0.0:
		_take_damage(_continuous_damage)
