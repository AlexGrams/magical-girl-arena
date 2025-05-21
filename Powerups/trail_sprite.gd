extends Sprite2D

@export var trail1:CompressedTexture2D
@export var trail2:CompressedTexture2D
@export var trail3:CompressedTexture2D

@export var flower1:Sprite2D
@export var flower2:Sprite2D
@export var flower3:Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = randf_range(0, 360)
	
	var flowers = [flower1, flower2, flower3]
	var random_trail = randi_range(1, 3)
	
	# Set a random flower texture and scale animation
	for flower in flowers:
		match random_trail:
			1:
				flower.texture = trail1
			2:
				flower.texture = trail2
			3:
				flower.texture = trail3
		random_trail = randi_range(1, 3)
		var tween = create_tween()
		tween.tween_property(flower, "scale", Vector2(1, 1), randf_range(0.25, 0.75)).set_trans(Tween.TRANS_BACK)
