class_name BulletPet
extends CharacterBody2D


## How fast the pet moves in units/second.
@export var _speed: float = 100.0
## Area component for checking which Enemies are within range of the pet.
@export var _attack_area: Area2D = null

## Which Enemy the pet is currently trying to attack.
var _target: Enemy = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if _target:
		velocity = (_target.global_position - global_position) * _speed
		move_and_slide()
	else:
		_get_highest_health_nearby_enemy()


## Sets the Pet's target to the Enemy with the highest health value in the nearby range.
func _get_highest_health_nearby_enemy() -> void:
	for area: Area2D in _attack_area.get_overlapping_areas():
		var highest_health_enemy = null
		
		if area.get_parent() is Enemy:
			var enemy: Enemy = area.get_parent()
			if not highest_health_enemy or enemy.health > highest_health_enemy.health:
				highest_health_enemy = enemy
		if highest_health_enemy:
			_target = highest_health_enemy
			print(_target.name)
