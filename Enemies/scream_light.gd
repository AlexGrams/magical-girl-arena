extends Node2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
	
func set_tell_time(_tell_time: float):
	anim_player.speed_scale = 1.0/_tell_time
	
func play_scream():
	anim_player.speed_scale = 1
	anim_player.play("scream")
	
