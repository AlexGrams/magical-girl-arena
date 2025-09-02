class_name PowerupBall
extends Powerup
## A ball that can be kicked around by players. Damages Enemies that it touches, growing bigger
## with each kill until it explodes and returns to its starting size.


## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""

signal crit_changed(new_crit_chance: float, new_crit_multiplier: float)


func set_crit_chance(new_crit: float) -> void:
	super(new_crit)
	crit_changed.emit(crit_chance, crit_multiplier)


func _ready() -> void:
	super()


func _process(_delta: float) -> void:
	pass


func activate_powerup():
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
				get_parent().get_path()
			]
		]
	)


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1


func boost() -> void:
	push_warning("Ball has no boost functionality")
	pass


func unboost() -> void:
	pass
