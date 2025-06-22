extends Sprite2D

@export var PingPongBullet:Node2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var target = PingPongBullet._target
	if target != null:
		var direction = target.global_position - global_position
		rotation = direction.angle() + deg_to_rad(90)
