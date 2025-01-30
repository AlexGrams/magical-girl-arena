extends Bullet
## An ability that damages enemies in a large area and turns them into allies if they
## are killed by this attack.

@export var hitbox: BulletHitbox = null
var damage: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	# This bullet only lasts for a short time
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	print("Someone got hit by the ult")


# Set up other properties for this bullet
func setup_bullet(_data: Array) -> void:
	pass
