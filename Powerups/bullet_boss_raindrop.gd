class_name BulletBossRaindrop
extends Bullet
## A Bullet that waits some time before it does damage. A visual indicator shows where the bullet
## will damage and indicates how long until damage is applied.


## How big the shadow of this attack is at its maximum value.
var _max_shadow_scale: Vector2 = Vector2.ONE
## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## True for the one frame for which the bullet's collider is active
var _is_collision_active = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_max_shadow_scale = sprite.scale
	sprite.scale = Vector2.ZERO
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0


func _process(_delta: float) -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	death_timer += delta
	
	if death_timer >= lifetime:
		# Turn the hitbox on for one frame, then delete it.
		if not is_multiplayer_authority():
			return
		
		if not _is_collision_active:
			_is_collision_active = true
			collider.collision_layer = _collision_layer
		else:
			queue_free()
	else:
		sprite.scale = (death_timer / lifetime) * _max_shadow_scale
