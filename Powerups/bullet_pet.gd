class_name BulletPet
extends CharacterBody2D


## Max distance that the Pet can get from its owner before it is forced to return.
@export var _distance_threshold: float = 750.0
## How fast the pet moves in units/second.
@export var _speed: float = 100.0
## Time in seconds between attacks.
@export var _attack_time: float = 1.0
## Time in seconds that an Enemy remains taunted for.
@export var _taunt_duration: float = 5.0
## Time in seconds between the Pet taunting nearby Enemies.
@export var _taunt_cooldown: float = 10.0
## Component for damage collisions.
@export var _bullet_hitbox: BulletHitbox = null
## Area component for checking which Enemies are within range of the pet.
@export var _attack_area: Area2D = null
## Area component for detecting taunt collisions.
@export var _taunt_area: Area2D = null
## Setting sprite to angry when taunting
@export var _sprite: Node2D
# Audio for angry buzzing SFX. NOT looping buzz.
@export var _audio_player: AudioStreamPlayer2D

## Owning powerup level
var _current_level: int = 1
## Square of how far the pet can get from its owning player.
var _max_squared_distance: float = _distance_threshold ** 2
## Which Enemy the pet is currently trying to attack.
var _target: Node2D = null
## True when the current target is an Enemy, false if it is following the player.
var _is_targeting_enemy: bool = false
## Path to the Node2D that owns this pet. The pet returns to its owner when it isn't attacking.
var _owner_node: PlayerCharacterBody2D = null
## Current time until the next attack.
var _attack_timer: float = 0.0
## Time until next use of the taunt ability.
var _taunt_timer: float = 0.0
## Default collision layer for the pet's attack.
var _bullet_collision_layer: int = 0
## Default collision mask for taunt effects.
var _taunt_collision_mask: int = 0
## Changes how fast the Pet attacks when it is boosted.
var _attack_speed_boost: float = 1.0


## Initialize this pet.
@rpc("any_peer", "call_local")
func set_up(owner_path: String, starting_position: Vector2, damage: float, owner_id: int, powerup_index: int, level: int) -> void:
	_owner_node = get_tree().root.get_node(owner_path)
	global_position = starting_position
	set_multiplayer_authority(1)
	_bullet_hitbox.damage = damage
	if _current_level < level:
		_current_level = level
	
	# Analytics information
	_bullet_hitbox.owner_id = owner_id
	_bullet_hitbox.powerup_index = powerup_index
	
	if owner_id != multiplayer.get_unique_id():
		_sprite.set_opacity()

	
	# Level up functionality
	var pet_powerup = _owner_node.get_node_or_null("PowerupPet")
	if pet_powerup != null and pet_powerup is Powerup:
		pet_powerup.powerup_level_up.connect(func(new_level: int, new_damage: float):
			level_up.rpc(new_level, new_damage)
		)
		# It is possible that this bullet was leveled up before it was set up.
		level_up.rpc(pet_powerup.current_level, _bullet_hitbox.damage)
	
	# When the owner goes down, destroy this bullet
	if is_multiplayer_authority():
		_owner_node.died.connect(func():
			queue_free()
		)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_bullet_collision_layer = _bullet_hitbox.collision_layer
	_taunt_collision_mask = _taunt_area.collision_mask
	_taunt_area.collision_mask = 0


# Called every frame on the multiplayer authority.
func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# To attack, flicker the Bullet hitbox collision area for one physics frame.
		if _attack_time == _attack_timer:
			_bullet_hitbox.collision_layer = _bullet_collision_layer
		_attack_timer -= delta * _attack_speed_boost
		if _attack_timer <= 0.0:
			_bullet_hitbox.collision_layer = 0
			_attack_timer = _attack_time
		
		# Taunt: Activate the taunt area for one physics frame.
		if _current_level >= 3:
			if _taunt_cooldown == _taunt_timer:
				_taunt_area.collision_mask = 0
			_taunt_timer -= delta
			if _taunt_timer <= 0.0:
				# Turn sprite angry
				_sprite.set_angry()
				# Play angry sound once
				_audio_player.play()
				
				# Activate taunt collision area
				_taunt_area.collision_mask = _taunt_collision_mask
				_taunt_timer = _taunt_cooldown
	
	# Movement and targeting
	if _target != null:
		velocity = (_target.global_position - global_position) * _speed
		move_and_slide()
	if _target == null or not _is_targeting_enemy:
		_get_target()


## Sets the Pet's target to the Enemy closest to the Pet.
func _get_target() -> void:
	# Go back to the player if we get too far from them.
	if _owner_node.position.distance_squared_to(self.position) > _max_squared_distance:
		_is_targeting_enemy = false
		_target = _owner_node
		return
	
	var closest_distance_squared := INF
	_target = null
	
	for area: Area2D in _attack_area.get_overlapping_areas():
		var enemy = area.get_parent()
		if enemy is Enemy:
			var distance_squared = self.position.distance_squared_to(enemy.position)
			if not _target or distance_squared < closest_distance_squared:
				_target = enemy
				closest_distance_squared = distance_squared
	
	if _target != null:
		_is_targeting_enemy = true
	else:
		# If we couldn't find an Enemy to target, then just go to the owning player.
		_is_targeting_enemy = false
		_target = _owner_node


@rpc("any_peer", "call_local")
func teleport(new_position: Vector2) -> void:
	global_position = new_position


# This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(new_level: int, new_damage: float):
	if new_level < _current_level:
		return
	
	_bullet_hitbox.damage = new_damage
	_current_level = new_level
	if _current_level == 3:
		_taunt_cooldown = 8
		_attack_time = 0.75


func boost() -> void:
	_attack_speed_boost *= 2.0


func unboost() -> void:
	_attack_speed_boost /= 2.0


## Apply taunt to Enemies in this area. Taunt area collisions are only handled on the server.
func _on_taunt_area_2d_entered(area: Area2D) -> void:
	if area.get_parent() is Enemy:
		area.get_parent().apply_status_taunted.rpc(_taunt_duration, get_path())


func _on_audio_stream_player_2d_finished() -> void:
	print("FINISHED")
