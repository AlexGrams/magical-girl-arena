extends Node2D

@export var starting_type:Constants.EnemySpriteType
@export var sprite_components:Array[Sprite2D]
@export var standard_sprites:Array[CompressedTexture2D]
@export var special_sprites:Array[CompressedTexture2D]
@export var goth_sprites:Array[CompressedTexture2D]
@onready var anim_player:AnimationPlayer = $AnimationPlayer
@onready var original_anim_speed:float = anim_player.speed_scale
@onready var default_anim:String = anim_player.current_animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_color(starting_type)
	assert(len(sprite_components) == len(standard_sprites))
	assert(len(sprite_components) == len(special_sprites))
	assert(len(sprite_components) == len(goth_sprites))

func change_color(type: Constants.EnemySpriteType):
	var counter = 0
	match type:
		Constants.EnemySpriteType.STANDARD:
			for sprite in sprite_components:
				sprite.texture = standard_sprites[counter]
				counter += 1
		Constants.EnemySpriteType.SPECIAL:
			for sprite in sprite_components:
				sprite.texture = special_sprites[counter]
				counter += 1
		Constants.EnemySpriteType.GOTH_ALLY:
			for sprite in sprite_components:
				sprite.texture = goth_sprites[counter]
				counter += 1

# Plays "take_damage" animation
func take_damage():
	if anim_player.has_animation("take_damage"):
		anim_player.speed_scale = 2
		anim_player.play("take_damage")
		await anim_player.animation_finished
		# Play default looping animation after take_damage is done
		anim_player.speed_scale = original_anim_speed
		anim_player.play(default_anim)
