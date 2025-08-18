extends Control

@export var sprite_pos:Control
@export var character_select_container:Container

const character_animated_sprite: Resource = preload("res://UI/character_animated_sprite.tscn")
var sprite:CharacterAnimatedSprite2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Add visual character sprite
	if sprite == null:
		sprite = character_animated_sprite.instantiate()
		sprite.global_position = sprite_pos.global_position
		sprite.flip_h = true
		sprite.set_read_input(false)
		sprite.set_character(Constants.Character.GOTH)
		sprite.set_read_input(false)
		sprite.set_model_scale(1.8)
		add_child(sprite)
	
	# Change character sprite when buttons are pressed
	for button: Button in character_select_container.get_children():
		button.pressed.connect(func():
			_on_character_select_button_pressed(button)
		)

func _on_character_select_button_pressed(button):
	sprite.set_character(button.character)
