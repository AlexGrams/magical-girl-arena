extends Powerup


## Time in seconds between firing.
@export var _fire_interval = 3.0
## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""

@onready var _fire_timer: float = _fire_interval
var _owner: PlayerCharacterBody2D = null
var _has_level_3_upgrade: bool = false


func _ready() -> void:
	super()
	_owner = get_parent()
	
	# Crits by default
	crit_chance = 0.25
	crit_multiplier = 2.0


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_fire_timer += delta
	if _fire_timer > _fire_interval:
		var crit: bool = randf() <= crit_chance
		var total_damage: float = _get_damage_from_curve() * (1.0 if not crit else crit_multiplier)
		for player: PlayerCharacterBody2D in GameState.player_characters.values():
			if player != _owner:
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
							player.get_path(), 
							_has_level_3_upgrade,
							crit_chance,
							crit_multiplier
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
		_has_level_3_upgrade = true


func boost() -> void:
	_fire_interval /= 2.0


func unboost() -> void:
	_fire_interval *= 2.0


func boost_fire_rate() -> void:
	_fire_interval /= 2.0
