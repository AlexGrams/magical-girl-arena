extends Bullet


@export var _area: Area2D = null
## Contains the visuals and collision for the bullet.
@export var _lightning: Node2D = null

var _processed: bool = false


func _ready() -> void:
	# This is intentionally blank. It overrides Bullet's _ready() function.
	pass


func _process(_delta: float) -> void:
	# This is intentionally blank. It overrides Bullet's _process() function.
	pass


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not _processed:
		_processed = true
	else:
		queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or (typeof(data[0])) != TYPE_NODE_PATH	# Target endpoint
	):
		push_error("Malformed data array")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	var rotation_direction: Vector2 = get_node(data[0]).global_position - global_position
	global_position += rotation_direction / 2
	rotation = rotation_direction.angle()
	_lightning.scale.x = rotation_direction.length()
