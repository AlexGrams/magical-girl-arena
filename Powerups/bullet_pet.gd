class_name BulletPet
extends CharacterBody2D


## How fast the pet moves in units/second.
@export var _speed: float = 100.0
## Time in seconds between attacks.
@export var _attack_time: float = 1.0
## Component for damage collisions.
@export var _bullet_hitbox: BulletHitbox = null
## Area component for checking which Enemies are within range of the pet.
@export var _attack_area: Area2D = null

## Which Enemy the pet is currently trying to attack.
var _target: Enemy = null
## Current time until the next attack.
var _attack_timer: float = 0.0
## Default collision layer for the pet's attack.
var _bullet_collision_layer: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_bullet_collision_layer = _bullet_hitbox.collision_layer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# To attack, flicker the Bullet hitbox collision area for one frame.
	if _attack_time == _attack_timer:
		_bullet_hitbox.collision_layer = _bullet_collision_layer
	
	_attack_timer -= delta
	
	if _attack_timer < 0.0:
		_bullet_hitbox.collision_layer = 0
		_attack_timer = _attack_time


func _physics_process(delta: float) -> void:
	if _target != null:
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
