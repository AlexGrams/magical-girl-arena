extends Sprite2D

@export var breathe_animplayer: AnimationPlayer
@export var veil_animplayer: AnimationPlayer
@export var hand_animplayer: AnimationPlayer
@onready var players:Array[AnimationPlayer] = [breathe_animplayer, veil_animplayer, hand_animplayer]

func play_scream_anim() -> void:
	# Set up players to instantly turn on scream
	for player in players:
		player.playback_default_blend_time = 0
	breathe_animplayer.pause()
	
	# Wait for _tell_timer on bullet_boss_scream
	await get_tree().create_timer(2).timeout
	
	# Choose random scream anim
	if randf() > 0.5:
		veil_animplayer.play("scream_1")
	else:
		veil_animplayer.play("scream_2")
	if randf() > 0.5:
		hand_animplayer.play("sudden_left")
	else:
		hand_animplayer.play("sudden_right")
	
	# Gradually return to idle phase
	for player in players:
		player.playback_default_blend_time = 2

	await hand_animplayer.animation_finished
	breathe_animplayer.play("breathe")
	veil_animplayer.play("veil_idle")
	hand_animplayer.play("hand_idle")
