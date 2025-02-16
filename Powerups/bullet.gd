class_name Bullet
extends Node2D
## A projectile that damages characters it touches.
## Replicated across clients.
## Default behavior is to move forward for some time


@export var speed: float = 5
@export var lifetime: float = 2
## The bullet's collider that damages when it touches enemies or players.
@export var collider: Area2D = null

var direction: Vector2
var death_timer: float = 0


func set_damage(damage: float):
	$Area2D.damage = damage


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	global_position += direction * speed
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	if is_multiplayer_authority():
		queue_free()


# Set up other properties for this bullet
func setup_bullet(data: Array) -> void:
	# Make the bullet hurt players
	if len(data) >= 1 and typeof(data[0]) == TYPE_BOOL:
		if not data[0]:
			if collider != null:
				collider.collision_layer = 0
				collider.collision_mask = 0
				collider.set_collision_layer_value(Constants.ENEMY_BULLET_COLLISION_LAYER, true)
				collider.set_collision_mask_value(Constants.ENEMY_BULLET_COLLISION_MASK, true)
