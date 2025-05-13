class_name CharacterAnimatedSprite2D
extends Sprite2D
# An animated sprite for displaying selected characters outside of the Playground.

@export var gdcubism_user_model:GDCubismUserModel
var character_data:CharacterData = Constants.CHARACTER_DATA[Constants.Character.GOTH]
# Float used to rescale model if character changes
var previous_model_scale_multiplier:float = 1

var last_direction = "move_right"

# True if this sprite changes state depending on local user input.
var _read_input := true
var is_dead:bool = false

func set_character(character: Constants.Character, is_corrupted:bool = false) -> void:
	character_data = Constants.CHARACTER_DATA[character]
	_set_sprite(is_corrupted)
	
func set_read_input(new_val: bool) -> void:
	_read_input = new_val

func _set_sprite(is_corrupted:bool = false) -> void:
	if character_data == null:
		push_error("Character not set!")
		
	if is_corrupted:
		gdcubism_user_model.set_assets(character_data.corrupted_model_file_path)
	else:
		gdcubism_user_model.set_assets(character_data.model_file_path)
	
	# If scale multiplier differs, we need to rescale
	if character_data.model_scale_multiplier != previous_model_scale_multiplier:
		set_model_scale(gdcubism_user_model.adjust_scale / previous_model_scale_multiplier)
		previous_model_scale_multiplier = character_data.model_scale_multiplier
		
	# Some models have different heights, but models are centered,
	# so this offsets their y position so their feet are all at the same spot
	gdcubism_user_model.adjust_position.y = character_data.offset_height

func set_model_scale(new_scale: float) -> void:
	gdcubism_user_model.adjust_scale = new_scale * character_data.model_scale_multiplier

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Blinking_AnimationPlayer.play("Blinking")

# Called by death signal
func play_death_animation() -> void:
	is_dead = true
	if character_data.name == "Vale": # ONLY VALE IS DONE RIGHT NOW
		$Live2D_AnimationPlayer.play(character_data.name + "_Death")

func play_revive_animation() -> void:
	is_dead = false
	# No animation done yet.

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(character_data):
		push_error("Character not set!")
	# Simple animation if we don't care about user input.
	if not is_dead:
		if not _read_input:
			$Live2D_AnimationPlayer.play(character_data.name + "_Idle")
			$Live2D_AnimationPlayer.speed_scale = 1
			return
		
		var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_direction != Vector2.ZERO:
			$Live2D_AnimationPlayer.play(character_data.name + "_Walking")
			$Live2D_AnimationPlayer.speed_scale = 2
		else:
			$Live2D_AnimationPlayer.play(character_data.name + "_Idle")
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
	
