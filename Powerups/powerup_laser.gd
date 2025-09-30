class_name PowerupLaser
extends Powerup


@export var bullet_scene := "res://Powerups/bullet_laser.tscn"
@export var max_range: float = 500

## Time in seconds that ultimate cooldown is reduced each frame that this Energy powerup does damage.
@export var _energy_charm_ult_time_reduction: float = 0.1

## Owning player's ultimate ability.
var _owner_ultimate: Ability = null

signal update_pointer_location(new_pointer_location: Vector2)
## Signals to the laser bullet to activate signature functionality if this powerup is signature and max level.
signal activate_piercing()
## Called when the crit values for this powerup are changed.
signal crit_changed(new_crit_chance: float, new_crit_multiplier: float)


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_crit_multiplier(new_multiplier: float) -> void:
	super(new_multiplier)
	crit_changed.emit(crit_chance, crit_multiplier)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_pointer_location.emit(get_global_mouse_position())
	
	# Energy charm
	if _energy_did_damage:
		_owner_ultimate.current_cooldown_time -= _energy_charm_ult_time_reduction
	_energy_did_damage = false


func activate_powerup():
	super()
	
	if _deactivation_sources <= 0:
		is_on = true
		
		if _is_owned_by_player:
			_owner_ultimate = get_parent().abilities[0]
			# Main laser
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
						current_level >= 3,
						crit_chance,
						crit_multiplier
					]
				]
			)
			
			if current_level == 5 and is_signature:
				_activate_signature()
		else:
			pass


func deactivate_powerup():
	super()
	is_on = false
	
	if current_level == 5 and is_signature:
		get_parent().hide_lasers.rpc()


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if current_level == 3:
		activate_piercing.emit()
	if current_level == 5 and is_signature:
		_activate_signature()


## Add 2 extra lasers
func _activate_signature() -> void:
	get_parent().show_lasers.rpc()
	for laser: Node in get_parent().get_lasers():
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
					laser.get_path(), 
					true,
					crit_chance,
					crit_multiplier
				]
			]
		)
