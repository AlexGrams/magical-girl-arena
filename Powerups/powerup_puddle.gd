extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 1.0
## Number of bullets that are created each firiing.
@export var _puddles: int = 5
## Minimum distance from the player that a puddle can spawn.
@export var _min_range: float = 200.0
## Farthest that a bullet can be spawned from the player.
@export var _max_range: float = 500.0
## Time in seconds before each puddle is destroyed.
@export var _puddle_lifetime: float = 5.0
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
## Path to the PowerupData resource file for this Powerup.
@export var _powerup_data_file_path: String = ""

@onready var _fire_timer: float = _fire_interval
var _bullet_spawner: BulletSpawner = null


func _ready() -> void:
	powerup_name = load(_powerup_data_file_path).name
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		for i in range(_puddles):
			# Each mine is moved to a random position in a circle around the player.
			var displacement: Vector2 = Vector2.UP.rotated(randf_range(0, 2 * PI)) * randf_range(_min_range, _max_range)
			_bullet_spawner.request_spawn_bullet.rpc_id(
					1,
					[
						_bullet_scene, 
						global_position + displacement, 
						Vector2.ZERO, 
						_get_damage_from_curve(), 
						_is_owned_by_player,
						multiplayer.get_unique_id(),
						_powerup_index,
						[_puddle_lifetime, current_level >= 3]
					]
				)
		
		# TODO: Play sound effect
		# AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CUPID_ARROW)
		_fire_timer = 0.0


func activate_powerup():
	is_on = true


func deactivate_powerup():
	is_on = false
	_fire_timer = 0.0


func level_up():
	current_level += 1
