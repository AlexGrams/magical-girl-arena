class_name PowerupTether
extends Powerup


@export var bullet_scene := "res://Powerups/bullet_tether.tscn"
@export var max_range: float = 999999.0

## Time in seconds that ultimate cooldown is reduced each frame that this Energy powerup does damage.
@export var _energy_charm_ult_time_reduction: float = 0.1

## Owning player's ultimate ability.
var _owner_ultimate: Ability = null
## Instantiated bullets for this tether.
var _bullets: Array[BulletTether] = []

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float)


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_crit_multiplier(new_multiplier: float) -> void:
	super(new_multiplier)
	crit_changed.emit(crit_chance, crit_multiplier)


func add_bullet(bullet: BulletTether) -> void:
	_bullets.append(bullet)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


func _physics_process(_delta: float) -> void:
	# Energy charm
	if _energy_did_damage:
		_owner_ultimate.current_cooldown_time -= _energy_charm_ult_time_reduction
	_energy_did_damage = false


func activate_powerup():
	is_on = true
	
	if _is_owned_by_player:
		if _is_owned_by_player:
			_owner_ultimate = get_parent().abilities[0]
		if current_level < 3:
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
						crit_chance,
						crit_multiplier
					]
				]
			)
		else:
			_activate_level_three()
	else:
		pass


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	if current_level == 3:
		_activate_level_three()
	powerup_level_up.emit(current_level, _get_damage_from_curve())


## Creates one tether for each other player.
func _activate_level_three() -> void:
	for bullet: BulletTether in _bullets:
		bullet.destroy.rpc_id(1)
	
	for player: Node2D in GameState.player_characters.values():
		if player != get_parent():
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
						player.get_path(),
						crit_chance,
						crit_multiplier
					]
				]
			)
