extends Sprite2D

var last_direction = "move_down"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scale = Vector2(0.125, 0.125)

func _physics_process(_delta: float) -> void:
	#var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Prioritizes direction that was just pressed
	if Input.is_action_just_pressed("move_up"):
		frame = 2
		flip_h = false
		last_direction = "move_up"
	elif Input.is_action_just_pressed("move_right"):
		frame = 1
		flip_h = false
		last_direction = "move_right"
	elif Input.is_action_just_pressed("move_left"):
		frame = 1
		flip_h = true # If moving left, flip the sprite so she's facing left
		last_direction = "move_left"
	elif Input.is_action_just_pressed("move_down"):
		frame = 0
		flip_h = false
		last_direction = "move_down"
	# If player isn't moving or no new directions are made,
	# keeps direction they were facing in last
	elif Input.is_action_pressed(last_direction):
		pass
	# Allows player to move left, move down left, and move left again smoothly
	elif Input.is_action_pressed("move_up"):
		frame = 2
		flip_h = false
	elif Input.is_action_pressed("move_right"):
		frame = 1
		flip_h = false
	elif Input.is_action_pressed("move_left"):
		frame = 1
		flip_h = true # If moving left, flip the sprite so she's facing left
	elif Input.is_action_pressed("move_down"):
		frame = 0
		flip_h = false
