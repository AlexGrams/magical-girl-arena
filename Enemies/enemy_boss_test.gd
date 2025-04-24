extends EnemyBoss


## Time in seconds between when the boss switches which attack pattern its doing.
@export var _pattern_interval: float = 5.0
## UIDs of Powerup scenes to add to the boss.
@export var powerups_to_add: Array[String] = []
## Lower values means the boss moves around in a larger circle.
@export var rotation_rate: float = 0.5

var _current_rotation: float = 0.0
## Time in seconds until the next pattern switch.
var _pattern_switch_timer: float = 0.0
## Which attack pattern the boss is currently doing.
var _pattern_index: int = 0


func _ready() -> void:
	super()
	
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


func _physics_process(delta: float) -> void:
	if target != null:
		_current_rotation += rotation_rate * delta
		velocity = Vector2.LEFT.rotated(_current_rotation) * speed
		move_and_slide()
	else:
		if is_multiplayer_authority():
			_find_new_target()
		else:
			move_and_slide()
