extends GPUParticles2D
# Used for the afterimages of Goth Scythe powerup

@export var original_sprite:Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = original_sprite.position
	rotation = original_sprite.rotation
