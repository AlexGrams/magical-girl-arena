extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LakeAnimationPlayer.play("Wave1")
	await get_tree().create_timer(2.0).timeout
	$LakeAnimationPlayer3.play("Wave3")
	await get_tree().create_timer(4.0).timeout
	$LakeAnimationPlayer2.play("Wave2")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
