extends PointLight2D

@export var boss_enemy_spawner:Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Center lighting on boss
	global_position = boss_enemy_spawner.global_position

func grow_darkness() -> void:
	$AnimationPlayer.play("grow_darkness")

func shrink_darkness() -> void:
	$AnimationPlayer.play("shrink_darkness")

func move_camera(to_pos:Vector2) -> void:
	# Get player camera
	var player = GameState.get_local_player()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(player.get_node("Camera2D"), "global_position", to_pos, 1)
	
func reset_camera() -> void:
	# Get player camera
	var player = GameState.get_local_player()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(player.get_node("Camera2D"), "position", Vector2.ZERO, 1)
