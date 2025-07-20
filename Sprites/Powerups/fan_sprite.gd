extends Bullet
## Purely visual. Is only a bullet type so that it can use the same replication systems as Bullets.


## Character that owns this powerup.
var _owner: PlayerCharacterBody2D = null
## Rotation from most recent direction input.
var _direction: float = 0.0


func set_damage(_damage: float):
	pass


func _ready() -> void:
	pass

func play_wind() -> void:
	$Wind/AnimationPlayer.play("wind")

func _process(_delta: float) -> void:
	if _owner != null:
		if _owner.input_direction != Vector2.ZERO:
			_direction = _owner.input_direction.angle()
		global_position = _owner.global_position
		rotation = _direction


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning player
	):
		push_error("Malformed data array")
		return
	
	_is_owned_by_player = is_owned_by_player
	_owner = get_tree().root.get_node(data[0])
	
	# This bullet destroys itself when the player dies.
	if is_multiplayer_authority():
		_owner.died.connect(func():
			queue_free()
		)


func take_damage(_damage: float) -> void:
	pass
