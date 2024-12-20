extends Bullet

@export var radius = 2


func set_damage(damage:float):
	$BulletOffset/Area2D.damage = damage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BulletOffset.position.y = radius


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(speed * delta)
