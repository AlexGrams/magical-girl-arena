extends Powerup

# TODO: Promote to a member of Powerup
var is_on: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func activate_powerup():
	is_on = true


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	#bullet_damage = upgrade_curve.sample(float(current_level) / max_level)
	#powerup_level_up.emit(current_level, bullet_damage)
