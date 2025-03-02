extends Powerup


@export var max_range: float = 500

# TODO: Promote to a member of Powerup
var is_on: bool = false

var _parent: Node2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# TODO: Use logic similar to the Orbit powerup and make it so that the laser is spawned, persists for 
# the duration that this powerup is active, and sets its position according to the raycast math below.
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position, 
		global_position + (get_global_mouse_position() - global_position).normalized() * max_range
	)
	var result = space_state.intersect_ray(query)
	if result:
		# The laser hit something and shouldn't be its full length.
		pass
	else:
		# The laser extends to its max range.
		pass


func activate_powerup():
	is_on = true
	_parent = get_parent()


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	#bullet_damage = upgrade_curve.sample(float(current_level) / max_level)
	#powerup_level_up.emit(current_level, bullet_damage)
