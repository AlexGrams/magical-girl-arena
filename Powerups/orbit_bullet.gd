extends Bullet

@export var radius = 2


func set_damage(damage:float):
	$BulletOffset/Area2D.damage = damage


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	rotate(speed * delta)


# Set up other properties for this bullet
func setup_bullet(_data: Array) -> void:
	$BulletOffset.position.y = radius
	
	# This bullet is parented to the player and destroys itself when the player dies.
	$"..".died.connect(func(): 
		queue_free()
	)
