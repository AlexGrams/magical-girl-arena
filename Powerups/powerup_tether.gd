class_name PowerupTether
extends Powerup


@export var bullet_scene := "res://Powerups/bullet_tether.tscn"
@export var max_range: float = 500

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float)


func set_crit_chance(new_crit: float) -> void:
	crit_chance = new_crit
	crit_changed.emit(crit_chance, crit_multiplier)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
				_get_damage_from_curve(), 
				false,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[
					get_parent().get_path(), 
					max_range, 
					get_parent().get_path(), 
					false,
					crit_chance,
					crit_multiplier
				]
			]
		)
	else:
		pass


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	
	# At level 3, double max range.
	if current_level == 3:
		max_range = 999999
