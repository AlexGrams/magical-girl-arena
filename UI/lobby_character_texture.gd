extends Control
# Animates the textures showing the characters on the Lobby screen.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Blinking_AnimationPlayer.play("Blinking")
	$Live2D_AnimationPlayer.play("Breathing")
