class_name BossPointLight2D
extends PointLight2D
## Can grow, shrink, and move the camera for doing boss cutscenes. 

@export var boss_enemy_spawner:Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Center lighting on boss
	global_position = boss_enemy_spawner.global_position


func grow_darkness() -> void:
	$AnimationPlayer.play("grow_darkness")


func shrink_darkness() -> void:
	$AnimationPlayer.play("shrink_darkness")


## Returns signal that is called when animation finishes.
func move_camera(to_pos:Vector2) -> Signal:
	# Get player camera
	var player = GameState.get_local_player()
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(player.get_node("Camera2D"), "global_position", to_pos, 1)
	return tween.finished


## Returns signal that is called when animation finishes.
func reset_camera() -> Signal:
	# Get player camera
	var player = GameState.get_local_player()
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(player.get_node("Camera2D"), "position", Vector2.ZERO, 1)
	return tween.finished
