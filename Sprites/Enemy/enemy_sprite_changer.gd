extends Node2D

@export var starting_type:Constants.EnemySpriteType
@export var sprite_components:Array[Sprite2D]
@export var standard_sprites:Array[CompressedTexture2D]
@export var special_sprites:Array[CompressedTexture2D]
@export var goth_sprites:Array[CompressedTexture2D]

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
