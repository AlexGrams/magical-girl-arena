class_name PowerupBall
extends Powerup
## A ball that can be kicked around by players. Damages Enemies that it touches, growing bigger
## with each kill until it explodes and returns to its starting size.


## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
var _ball: BulletBall = null
var _kills: int = 0
var _total_growth: float = 0.0

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float)


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func set_ball(ball: BulletBall) -> void:
	_ball = ball
	if _area_size_boosted:
		_ball.boost_area_size.rpc()


func _ready() -> void:
	super()


func _process(_delta: float) -> void:
	pass


func activate_powerup():
	super()
	
	if _deactivation_sources > 0:
		return
	
	is_on = true
	GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
		1,
		[
			_bullet_scene, 
			global_position, 
			Vector2.ZERO, 
			_get_damage_from_curve(), 
			false,
			_is_owned_by_player,
			multiplayer.get_unique_id(),
			_powerup_index,
			[
				get_parent().get_path(),
				_kills,
				_total_growth
			]
		]
	)


func deactivate_powerup():
	super()
	is_on = false


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	push_warning("Ball has no boost functionality")
	pass


func unboost() -> void:
	pass


func boost_area_size() -> void:
	super()
	if _ball != null:
		_ball.boost_area_size.rpc()


## Called when instantiated ball grows. Keeps track of how big the ball should be when respawned.
func record_stats(kills: int, total_growth: float) -> void:
	_kills = kills
	_total_growth = total_growth
