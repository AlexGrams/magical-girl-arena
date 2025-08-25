extends LootBox


## Speed in units per second.
@export var _speed: float = 200.0 
@export var _character_body_2d: CharacterBody2D = null


func _physics_process(_delta: float) -> void:
	_character_body_2d.move_and_slide()
	
	# Hardcoded values to determine when the tumbleweed goes off the map.
	if is_multiplayer_authority() and global_position.x < -2000 or global_position.x > 4000:
		queue_free()


## Move LootBox to a location. Call using RPC for replication.
@rpc("authority", "call_local")
func teleport(pos: Vector2) -> void:
	super(pos)
	
	# Sort of a hack to move in the opposite direction across the arena.
	if global_position.x > 0:
		_character_body_2d.velocity = Vector2.LEFT * _speed
	else:
		_character_body_2d.velocity = Vector2.RIGHT * _speed
