extends LootBox


## Speed in units per second.
@export var _speed: float = 200.0 
@export var _character_body_2d: CharacterBody2D = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	_character_body_2d.velocity = Vector2.RIGHT * _speed
	_character_body_2d.move_and_slide()
