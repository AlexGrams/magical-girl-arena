extends Powerup
## Creates stationary mines around the player that explode after a delay


## Time in seconds between creating bullets.
@export var shoot_interval = 1.0
## Number of mines created per activation.
@export var _mines: int = 10
## Farthest distance that a mine is placed from the player.
@export var _max_range: float = 300.0
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""

@onready var _shoot_timer: float = shoot_interval
var _bullet_spawner: BulletSpawner = null


func _ready() -> void:
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		var crit: bool = randf() <= crit_chance
		var total_damage: float = _get_damage_from_curve() * (1.0 if not crit else crit_multiplier)
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.MINES_DROPPED)
		for i in range(_mines):
			# Each mine is moved to a random position in a circle around the player.
			var displacement: Vector2 = Vector2.UP.rotated(randf_range(0, 2 * PI)) * randf_range(0, _max_range)
			_bullet_spawner.request_spawn_bullet.rpc_id(
					1,
					[
						_bullet_scene, 
						global_position + displacement, 
						Vector2.ZERO, 
						total_damage, 
						crit,
						_is_owned_by_player,
						multiplayer.get_unique_id(),
						_powerup_index,
						[]
					]
				)
		
		_shoot_timer = 0


func activate_powerup():
	is_on = true


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
	if current_level == 3:
		shoot_interval = shoot_interval / 2


func boost() -> void:
	shoot_interval /= 2.0


func unboost() -> void:
	shoot_interval *= 2.0
