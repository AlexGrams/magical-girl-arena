extends EnemyBoss


## This test boss has all the powerups.
@export var powerups_to_add: Array[PackedScene] = []
## Lower values means the boss moves around in a larger circle.
@export var rotation_rate: float = 0.5

var _current_rotation: float = 0.0


func _ready() -> void:
	super()
	
	for powerup: PackedScene in powerups_to_add:
		if powerup != null:
			_add_powerup(powerup)


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
