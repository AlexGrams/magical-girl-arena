extends Powerup

## Time in seconds between shots.
@export var shoot_interval: float  = 0.25
## Time in seconds between shots when the powerup is at max level.
@export var max_level_shoot_interval: float = 0.06
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
	# TODO: Make these properties read from the PowerupData instead of setting them here.
	bullet_damage = upgrade_curve.sample(float(current_level) / max_level)
	if current_level >= max_level:
		_rotation = _max_level_rotation
		shoot_interval = max_level_shoot_interval


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_on:
		shoot_timer += delta
		if shoot_timer > shoot_interval:
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1, [bullet_scene, 
					global_position, 
					direction, 
					bullet_damage, 
					_is_owned_by_player,
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
	bullet_damage = upgrade_curve.sample(float(current_level) / max_level)
	
	# Shoot way faster at 5th level
	if current_level >= max_level:
		_rotation = _max_level_rotation
		shoot_interval = max_level_shoot_interval
	
	powerup_level_up.emit(current_level, bullet_damage)
