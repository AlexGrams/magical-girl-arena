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

@onready var _fire_timer: float = _fire_interval
@onready var _bounces: int = _max_bounces
@onready var _splits: int = _max_splits
## Path to owning node.
var _owner_path: NodePath


func _ready() -> void:
	super()
	_owner_path = get_parent().get_path()


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		var target_node: Node = _find_nearest_target()
		if target_node != null:
			var target_path: NodePath = target_node.get_path()
			var crit: bool = randf() <= crit_chance
			var total_damage: float = _get_damage_from_curve() * (1.0 if not crit else crit_multiplier)
			GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
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
						target_path, 
						_bounces,
						_splits,
						_owner_path
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


func boost_fire_rate() -> void:
	_fire_interval *= 0.75
