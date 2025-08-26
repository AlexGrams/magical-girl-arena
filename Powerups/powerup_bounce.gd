extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 1.0
## How many targets this bullet hits before it is destroyed.
@export var _max_bounces: int = 3
## Same as _max_bounces, but for level 3+
@export var _max_bounces_upgraded: int = 5
## Number of additional bounce bullets that are created each time the Bounce hits something.
@export var _max_splits: int = 1
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
## Path to the PowerupData resource file for this Powerup.
@export var _powerup_data_file_path: String = ""

@onready var _fire_timer: float = _fire_interval
@onready var _bounces: int = _max_bounces
@onready var _splits: int = _max_splits


func _ready() -> void:
	powerup_name = load(_powerup_data_file_path).name


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		var crit: bool = randf() <= crit_chance
		var total_damage: float = _get_damage_from_curve() * (1.0 if not crit else crit_multiplier)
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, 
			[
				_bullet_scene, 
				global_position, 
				Vector2.UP, 
				total_damage, 
				crit,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[
					_find_nearest_target().get_path(), 
					_bounces,
					_splits
				]
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
	
	## TODO: Extra bonus here.
	if current_level >= 3:
		_bounces = _max_bounces_upgraded


func boost() -> void:
	_fire_interval /= 2.0


func unboost() -> void:
	_fire_interval *= 2.0
