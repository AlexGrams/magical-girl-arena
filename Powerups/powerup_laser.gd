extends Powerup


@export var bullet_scene := "res://Powerups/bullet_laser.tscn"
@export var max_range: float = 500

# TODO: Promote to a member of Powerup
var is_on: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func activate_powerup():
	is_on = true
	
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				upgrade_curve.sample(float(current_level) / max_level), 
				_is_owned_by_player,
				[get_parent().get_path(), max_range]
			]
		)
	else:
		pass


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	# TODO: Figure out how to upgrade the laser
	#bullet_damage = upgrade_curve.sample(float(current_level) / max_level)
	#powerup_level_up.emit(current_level, bullet_damage)
