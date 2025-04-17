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
var _target: Node2D = null
## True when the current target is an Enemy, false if it is following the player.
var _is_targeting_enemy: bool = false
## Path to the Node2D that owns this pet. The pet returns to its owner when it isn't attacking.
var _owner_node: PlayerCharacterBody2D = null
## Current time until the next attack.
var _attack_timer: float = 0.0
## Default collision layer for the pet's attack.
var _bullet_collision_layer: int = 0


## Initialize this pet.
@rpc("any_peer", "call_local")
func set_up(owner_path: String, starting_position: Vector2) -> void:
	_owner_node = get_tree().root.get_node(owner_path)
	global_position = starting_position
	set_multiplayer_authority(1)
	
	# Level up functionality
	var pet_powerup = _owner_node.get_node_or_null("PetPowerup")
	if pet_powerup != null:
		pet_powerup.powerup_level_up.connect(func(new_level: int, new_damage: float):
			level_up.rpc(new_level, new_damage)
		)

	# When the owner goes down, destroy this bullet
	if is_multiplayer_authority():
		_owner_node.died.connect(func():
			queue_free()
		)
	
	# Client replications do not process.
	if not is_multiplayer_authority():
		set_process(false)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_bullet_collision_layer = _bullet_hitbox.collision_layer


# Called every frame on the multiplayer authority.
func _process(delta: float) -> void:
	# To attack, flicker the Bullet hitbox collision area for one frame.
	if _attack_time == _attack_timer:
		_bullet_hitbox.collision_layer = _bullet_collision_layer
	
	_attack_timer -= delta
	
	if _attack_timer < 0.0:
		_bullet_hitbox.collision_layer = 0
		_attack_timer = _attack_time


func _physics_process(_delta: float) -> void:
	if _target != null:
		velocity = (_target.global_position - global_position) * _speed
		move_and_slide()
	if _target == null or not _is_targeting_enemy:
		_get_highest_health_nearby_enemy()


## Sets the Pet's target to the Enemy with the highest health value in the nearby range.
func _get_highest_health_nearby_enemy() -> void:
	for area: Area2D in _attack_area.get_overlapping_areas():
		var highest_health_enemy = null
		
		if area.get_parent() is Enemy:
			var enemy: Enemy = area.get_parent()
			if not highest_health_enemy or enemy.health > highest_health_enemy.health:
				highest_health_enemy = enemy
		if highest_health_enemy != null:
			_is_targeting_enemy = true
			_target = highest_health_enemy
	
	# If we couldn't find an Enemy to target, then just go to the owning player.
	if _target == null:
		_is_targeting_enemy = false
		_target = _owner_node


@rpc("any_peer", "call_local")
func teleport(new_position: Vector2) -> void:
	global_position = new_position


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(_new_level: int, new_damage: float):
	_bullet_hitbox.damage = new_damage
