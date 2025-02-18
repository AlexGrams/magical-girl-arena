extends EnemyBoss

## This test boss has all the powerups.
@export var powerups_to_add: Array[PackedScene] = []


func _ready() -> void:
	super()
	
	for powerup: PackedScene in powerups_to_add:
		_add_powerup(powerup)
