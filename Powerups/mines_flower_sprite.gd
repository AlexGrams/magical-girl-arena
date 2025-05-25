extends Sprite2D

@export var petal:Texture2D
@export var petal2:Texture2D
@export var petal3:Texture2D

@export var all_petal_sprites:Array[Sprite2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var random_petal = [petal, petal2, petal3].pick_random()
	
	for petal_sprite: Sprite2D in all_petal_sprites:
		petal_sprite.texture = random_petal


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
