class_name PowerupLaser
extends Powerup


@export var bullet_scene := "res://Powerups/bullet_laser.tscn"
@export var max_range: float = 500

signal update_pointer_location(new_pointer_location: Vector2)
## Signals to the laser bullet to activate signature functionality if this powerup is signature and max level.
signal activate_signature()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_pointer_location.emit(get_global_mouse_position())


func activate_powerup():
	is_on = true
	
	if _is_owned_by_player:
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1,
			[
				bullet_scene, 
				Vector2.ZERO, 
				Vector2.ZERO, 
				_get_damage_from_curve(), 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[get_parent().get_path(), max_range]
			]
		)
	else:
		pass


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if current_level == max_level and is_signature:
		activate_signature.emit()
