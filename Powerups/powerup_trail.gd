extends Powerup

## Time between creating puddles
@export var shoot_interval: float = 1.0
## Path to the Bullet-derived bullet scene.
@export var bullet_scene := ""

var _shoot_timer: float = 0
## How much damage the powerup does at its current level.
var _damage: float = 0.0
## Lifetime for bullet. Doubles at level 3
var _trail_lifetime: float = 2

signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_damage = _get_damage_from_curve()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > shoot_interval:
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.TRAIL)
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, 
			[
				bullet_scene, 
				global_position, 
				Vector2.ZERO, 
				_damage,
				false,
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[_trail_lifetime]
			]
		)
		
		_shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit()


func deactivate_powerup():
	is_on = false
	_shoot_timer = 0.0


func level_up():
	current_level += 1
	_damage = _get_damage_from_curve()
	if current_level == 3:
		_trail_lifetime = _trail_lifetime * 2
	powerup_level_up.emit(current_level, _damage)


func boost() -> void:
	shoot_interval /= 2.0


func unboost() -> void:
	shoot_interval *= 2.0
