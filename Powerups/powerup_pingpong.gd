class_name PowerupPingPong
extends Powerup

## Time in seconds that ultimate cooldown is reduced each frame that this Energy powerup does damage.
@export var _energy_charm_ult_time_reduction: float = 0.5

var bullet_scene := "res://Powerups/bullet_pingpong.tscn"

var _bullets: Array[BulletPingPong] = []
## Owning player's ultimate ability.
var _owner_ultimate: Ability = null

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float) 
signal disabled()


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_crit_multiplier(new_multiplier: float) -> void:
	super(new_multiplier)
	crit_changed.emit(crit_chance, crit_multiplier)


func add_bullet(new_bullet: BulletPingPong) -> void:
	_bullets.append(new_bullet)


func _ready():
	super()


func _physics_process(_delta: float) -> void:
	# Energy charm
	if _energy_did_damage:
		_owner_ultimate.reduce_current_cooldown(_energy_charm_ult_time_reduction)
	_energy_did_damage = false


func activate_powerup():
	super()
	
	if _deactivation_sources > 0:
		return
	
	if _is_owned_by_player:
		_owner_ultimate = get_parent().abilities[0]
		var spawn_pingpong: Callable = func():
			GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
				1, 
				[
					bullet_scene, 
					global_position, 
					Vector2.UP, 
					_get_damage_from_curve(), 
					false,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[$"..".get_path()]
				]
			)
		spawn_pingpong.call_deferred()
	else:
		push_error("Enemy PingPong not implemented")


func deactivate_powerup():
	super()
	disabled.emit()


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	for bullet: BulletPingPong in _bullets:
		if bullet != null:
			bullet.boost.rpc()


func unboost() -> void:
	for bullet: BulletPingPong in _bullets:
		if bullet != null:
			bullet.unboost.rpc()


func boost_haste() -> void:
	for bullet: BulletPingPong in _bullets:
		if bullet != null:
			bullet.boost.rpc()
