extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 1.0
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
## Path to the PowerupData resource file for this Powerup.
@export var _powerup_data_file_path: String = ""

var _fire_timer: float = 0.0
## The last nonzero movement direction input.
var _direction: Vector2 = Vector2.RIGHT
var _bullet_spawner: BulletSpawner = null
var _owning_character: PlayerCharacterBody2D = null


func _ready() -> void:
	powerup_name = load(_powerup_data_file_path).name
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")


func _process(delta: float) -> void:
	if not is_on:
		return
	
	if _owning_character.input_direction != Vector2.ZERO:
		_direction = _owning_character.input_direction
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		print(_owning_character.input_direction)
		_bullet_spawner.request_spawn_bullet.rpc_id(
				1,
				[
					_bullet_scene, 
					global_position, 
					_direction, 
					_get_damage_from_curve(), 
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[]
				]
			)
		
		# TODO: Play sound effect
		# AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CUPID_ARROW)
		_fire_timer = 0.0


func activate_powerup():
	is_on = true
	_owning_character = get_parent()


func deactivate_powerup():
	is_on = false
	_fire_timer = 0.0


func level_up():
	current_level += 1
	
	## TODO: Extra bonus here.
	if current_level >= 3:
		pass
