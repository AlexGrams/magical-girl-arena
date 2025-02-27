class_name Bullet
extends Node2D
## A projectile that damages characters it touches.
## Replicated across clients.
## Default behavior is to move forward for some time


@export var speed: float = 5
@export var lifetime: float = 2
## If true, this bullet is destroyed the first time it collides with something.
@export var destroy_on_hit := true
## The bullet's collider that damages when it touches enemies or players.
@export var collider: Area2D = null
## The rendered part of the bullet. Used to change its color when Enemies shoot it.
@export var sprite: Sprite2D = null

var direction: Vector2
var death_timer: float = 0


func set_damage(damage: float):
	$Area2D.damage = damage


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	if is_multiplayer_authority() and destroy_on_hit:
		queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	# Make the bullet hurt players
	if not is_owned_by_player:
		_modify_collider_to_harm_players()


# Change the collision layer and mask values so that this bullet damages Players instead of Enemies.
func _modify_collider_to_harm_players() -> void:
	if collider != null:
		collider.collision_layer = 0
		collider.collision_mask = 0
		collider.set_collision_layer_value(Constants.ENEMY_BULLET_COLLISION_LAYER, true)
		collider.set_collision_mask_value(Constants.ENEMY_BULLET_COLLISION_MASK, true)
	else:
		push_error("Attempting to modify collider when no collider is set for this Bullet")
	
	if sprite != null:
		sprite.self_modulate = Color.RED
