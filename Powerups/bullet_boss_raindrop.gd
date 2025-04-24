class_name BulletBossRaindrop
extends Bullet
## A Bullet that waits some time before it does damage. A visual indicator shows where the bullet
## will damage and indicates how long until damage is applied.


## Time in seconds before this bullet activates and damages objects in its area.
@export var _warning_time: float = 1.0

## How big the shadow of this attack is at its maximum value.
var _max_shadow_scale: Vector2 = Vector2.ONE
## How much the shadow changes by in scale units per second.
var _shadow_delta: Vector2 = Vector2.ZERO
## Remaining time until this bullet does damage.
var _current_warning_time: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_max_shadow_scale = sprite.scale
	sprite.scale = Vector2.ZERO
	_current_warning_time = _warning_time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_current_warning_time -= delta
	
	if _warning_time <= 0.0:
		# Turn the hitbox on for one frame, then delete it.
		pass
	else:
		sprite.scale = (1.0 - (_current_warning_time / _warning_time)) * _max_shadow_scale
