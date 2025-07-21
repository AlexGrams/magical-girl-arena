extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var animation_player = $AnimationPlayer
	var animation_length: float = animation_player.get_animation("wing flap").length
	animation_player.play("wing flap")
	animation_player.seek(randf_range(0.0, animation_length))
