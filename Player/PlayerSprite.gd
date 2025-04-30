class_name CharacterAnimatedSprite2D
extends Sprite2D
# An animated sprite for displaying selected characters outside of the Playground.

@export var gdcubism_user_model:GDCubismUserModel

const GOTH := "res://addons/gd_cubism/example/res/live2d/Goth/runtime/GothVector0.model3.json"
const SWEET := "res://addons/gd_cubism/example/res/live2d/Sweet/runtime/Sweet.model3.json"

var last_direction = "move_right"

# True if this sprite changes state depending on local user input.
var _read_input := true


func set_read_input(new_val: bool) -> void:
	_read_input = new_val


func set_sprite(sprite: Constants.Character) -> void:
	match sprite:
		Constants.Character.GOTH:
			gdcubism_user_model.set_assets(GOTH)
		Constants.Character.SWEET:
			gdcubism_user_model.set_assets(SWEET)

func set_model_scale(new_scale: float) -> void:
	gdcubism_user_model.adjust_scale = new_scale


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Blinking_AnimationPlayer.play("Blinking")


func _physics_process(_delta: float) -> void:
	# Simple animation if we don't care about user input.
	if not _read_input:
		$Live2D_AnimationPlayer.play("Breathing")
		$Live2D_AnimationPlayer.speed_scale = 1
		return
	
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		$Live2D_AnimationPlayer.play("Walking")
		$Live2D_AnimationPlayer.speed_scale = 2
	else:
		$Live2D_AnimationPlayer.play("Breathing")
		$Live2D_AnimationPlayer.speed_scale = 1
		
	### This section is for 2-way sprites
	if Input.is_action_just_pressed("move_left"):
		flip_h = true
		last_direction = "move_left"
	elif Input.is_action_just_pressed("move_right"):
		flip_h = false
		last_direction = "move_right"
	elif Input.is_action_pressed(last_direction):
		pass
	elif Input.is_action_pressed("move_left"):
		flip_h = true
	elif Input.is_action_pressed("move_right"):
		flip_h = false
	
	### This section is for 4-way sprites
	## Prioritizes direction that was just pressed
	#if Input.is_action_just_pressed("move_up"):
		#frame = 2
		#flip_h = false
		#last_direction = "move_up"
	#elif Input.is_action_just_pressed("move_right"):
		#frame = 1
		#flip_h = false
		#last_direction = "move_right"
	#elif Input.is_action_just_pressed("move_left"):
		#frame = 1
		#flip_h = true # If moving left, flip the sprite so she's facing left
		#last_direction = "move_left"
	#elif Input.is_action_just_pressed("move_down"):
		#frame = 0
		#flip_h = false
		#last_direction = "move_down"
	## If player isn't moving or no new directions are made,
	## keeps direction they were facing in last
	#elif Input.is_action_pressed(last_direction):
		#pass
	## Allows player to move left, move down left, and move left again smoothly
	#elif Input.is_action_pressed("move_up"):
		#frame = 2
		#flip_h = false
	#elif Input.is_action_pressed("move_right"):
		#frame = 1
		#flip_h = false
	#elif Input.is_action_pressed("move_left"):
		#frame = 1
		#flip_h = true # If moving left, flip the sprite so she's facing left
	#elif Input.is_action_pressed("move_down"):
		#frame = 0
		#flip_h = false
