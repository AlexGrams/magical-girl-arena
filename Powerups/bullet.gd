class_name Bullet
extends Node2D
## A projectile that damages characters it touches.
## Replicated across clients.
## Default behavior is to move forward for some time


@export var speed: float = 5
@export var lifetime: float = 2
## If true, this bullet is destroyed the first time it collides with something.
@export var destroy_on_hit := true
## How much health this bullet has if it is owned by an Enemy.
@export var max_health: float = 50.0
## The bullet's collider that damages when it touches enemies or players.
@export var collider: Area2D = null
## The rendered part of the bullet. Used to change its color when Enemies shoot it.
@export var sprite: Sprite2D = null
## Type of sound to play when bullet is created
@export var sound_effect: SoundEffectSettings.SOUND_EFFECT_TYPE = -1

var direction: Vector2
var death_timer: float = 0

var _is_owned_by_player = true
var _health: float = 1.0


func set_damage(damage: float):
	collider.damage = damage


func _ready() -> void:
	if sound_effect != -1:
		AudioManager.create_audio_at_location(global_position, sound_effect)


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	if _is_owned_by_player:
		# Player's bullets should be destroyed when they hit something if applicable.
		if destroy_on_hit:
			queue_free()
	else:
		# Enemy's bullets should deal damage if they hit a player's bullet.
		# NOTE: Enemy bullets are deleted when the character that they hit calls an RPC to delete them.
		if area is BulletHitbox:
			take_damage(area.damage)


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	# Make the bullet hurt players
	if not is_owned_by_player:
		_is_owned_by_player = false
		_health = max_health
		_modify_collider_to_harm_players()


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	collider.owner_id = owner_id
	collider.powerup_index = powerup_index


## Do damage to this bullet. Bullets owned by enemies can be destroyed. Only call on 
## bullet's multiplayer owner.
func take_damage(damage: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_health -= damage
	if _health <= 0.0:
		queue_free()


# Change the collision layer and mask values so that this bullet damages Players instead of Enemies.
func _modify_collider_to_harm_players() -> void:
	if collider != null:
		collider.collision_layer = 0
		collider.collision_mask = 0
		collider.set_collision_layer_value(Constants.ENEMY_BULLET_COLLISION_LAYER, true)
		for mask in Constants.ENEMY_BULLET_COLLISION_MASK:
			collider.set_collision_mask_value(mask, true)
	else:
		push_error("Attempting to modify collider when no collider is set for this Bullet")
	
	if sprite != null:
		sprite.self_modulate = Color.RED
		
