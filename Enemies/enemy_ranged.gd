extends Enemy

# At most how far the enemy can be from the player before trying to shoot at them.
@export var max_range: float

# NOTE: I don't actually know how much performance we gain by doing this.
# Used for faster distance calculation
var squared_max_range: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	squared_max_range = max_range * max_range
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player != null:
		if global_position.distance_squared_to(player.global_position) > squared_max_range:
			global_position = global_position.move_toward(player.global_position, delta*speed)
		else:
			pass
