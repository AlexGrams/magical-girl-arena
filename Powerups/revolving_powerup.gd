extends Powerup

## Time in seconds between shots.
@export var shoot_interval: float  = 0.25
## Time in seconds between shots when the powerup is at max level.
@export var max_level_shoot_interval: float = 0.06
## Time in seconds betweene shots if owned by an enemy.
@export var enemy_shoot_interval: float = 0.75
@export var bullet_scene := "res://Powerups/revolving_bullet.tscn"

# TODO: Might not be used anymore
var sprite = preload("res://Orange.png")
var shoot_timer: float = 0
var direction := Vector2.RIGHT
var bullet_damage: float

## Current angle in degrees between one bullet and the next. 
var _rotation: float = 30.0
## Angle in degrees between one bullet and next when this powerup is at max level.
var _max_level_rotation: float = 10.0

signal picked_up_powerup(sprite)


func _ready() -> void:
	super()
	bullet_damage = _get_damage_from_curve()
	if is_signature and current_level >= max_level:
		_rotation = _max_level_rotation
		shoot_interval = max_level_shoot_interval


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_on:
		shoot_timer += delta
		# Use a different shoot interval depending on if a player or enemy owns this powerup.
		if (
			(_is_owned_by_player and shoot_timer > shoot_interval)
			or (not _is_owned_by_player and shoot_timer > enemy_shoot_interval)
		):
			var crit: bool = randf() <= crit_chance
			var total_damage: float = _get_damage_from_curve() * (1.0 if not crit else crit_multiplier)
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1, [bullet_scene, 
					global_position, 
					direction, 
					total_damage, 
					crit,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[]
				]
			)
			
			direction = direction.rotated(deg_to_rad(_rotation)).normalized()
			
			shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit(sprite)


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
	bullet_damage = _get_damage_from_curve()
	
	if current_level == 3:
		shoot_interval = shoot_interval + ((max_level_shoot_interval - shoot_interval) / 2)
	# Shoot way faster at 5th level
	if is_signature and current_level >= max_level:
		set_signature_settings()
	
	powerup_level_up.emit(current_level, bullet_damage)

func set_is_signature(value: bool) -> void:
	is_signature = value
	if is_signature and current_level >= max_level:
		set_signature_settings()

func set_signature_settings() -> void:
	bullet_damage = signature_damage
	_rotation = _max_level_rotation
	shoot_interval = max_level_shoot_interval


func boost() -> void:
	shoot_interval /= 2.0


func unboost() -> void:
	shoot_interval *= 2.0


func boost_fire_rate() -> void:
	shoot_interval /= 2.0
