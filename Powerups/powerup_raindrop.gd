extends Powerup
## Shoots expanding bubbles that suck in Enemies that it touches before exploding.


## Time in seconds between activation of bullets directly on the players.
@export var _shoot_interval: float = 2.0
## Maximum distance at which an Enemy can be from the player in order for this powerup to target them.
@export var _range: float = 1000.0
## UID of the scene for the powerup bullets
@export var _bullet_scene_uid := ""
## Area for finding groups of Enemies near the player.
@export var _nearby_collision_area: Area2D = null

@onready var _shoot_timer: float = _shoot_interval
## Used to boost bullet speed.
var _speed_multiplier: float = 1.0
## used to boost bullet expansion speed.
var _growth_speed_multiplier: float = 1.0
var _bullet_spawner: BulletSpawner = null
var _owner: PlayerCharacterBody2D = null


func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
	
	_bullet_spawner = GameState.playground.bullet_spawner
	_owner = get_parent()


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		# Fire towards a random nearby enemy.
		var near_areas = _nearby_collision_area.get_overlapping_areas()
		
		# Get a random nearby node.
		var target: Node2D = null 
		for area: Area2D in near_areas:
			target = area.get_parent()
			if target != null:
				break
		
		if target != null:
			var direction: Vector2 = (target.global_position - global_position).normalized()
			# bullet speed is increased depending on the owner's speed stat.
			var speed_boost: float = float(_owner.get_stat_speed() - 1) * 0.2
			var crit: bool = randf() <= crit_chance
			var total_damage: float = _get_damage_from_curve() * (1.0 if not crit else crit_multiplier)
			_bullet_spawner.request_spawn_bullet.rpc_id(
				1, 
				[
					_bullet_scene_uid, 
					global_position, 
					direction, 
					total_damage, 
					crit,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[
						_speed_multiplier + speed_boost, 
						_growth_speed_multiplier
					]
				]
			)
			if current_level >= 3:
				# Level three functionality: shoot two additional bullets in a triangle pattern relative to the first
				for i in range(2):
					direction = direction.rotated(2 * PI / 3)
					_bullet_spawner.request_spawn_bullet.rpc_id(
						1, 
						[
							_bullet_scene_uid, 
							global_position, 
							direction, 
							total_damage, 
							crit,
							_is_owned_by_player,
							multiplayer.get_unique_id(),
							_powerup_index,
							[
								_speed_multiplier + speed_boost, 
								_growth_speed_multiplier
							]
						]
					)
		_shoot_timer = _shoot_interval


func activate_powerup():
	is_on = true
	_shoot_timer = _shoot_interval


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	_shoot_interval /= 2.0
	_speed_multiplier *= 1.5
	_growth_speed_multiplier *= 2.0


func unboost() -> void:
	_shoot_interval *= 2.0
	_speed_multiplier /= 1.5
	_growth_speed_multiplier /= 2.0
