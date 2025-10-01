class_name PowerupShotgun
extends Powerup
## Shoots many small bullets in a cone towards the nearest enemy.

@export var shoot_interval: float = 1.0
@export var bullet_damage: float = 50.0
@export var _bullet_uid := "res://Powerups/bullet.tscn"
## How many bullets are made per firing
@export var _num_bullets: int = 6
## Angle in degrees for which bullets are evenly spread towards the target.
## Bullets are angled at most _fire_angle/2 degrees away from the target.
@export var _fire_angle: float = 45.0
## Time in seconds that ultimate cooldown is reduced each frame that this Energy powerup does damage.
@export var _energy_charm_ult_time_reduction: float = 0.25

@onready var shoot_timer: float = shoot_interval
# Toggles between left and right directions
var direction_toggle: bool = false
## Angle in radians of far apart each bullet is spread.
var _fire_angle_rad_delta: float = 0
## Owning player's ultimate ability.
var _owner_ultimate: Ability = null

var signature_active: bool = false
var signature_direction_toggle: int = 0
signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	bullet_damage = _get_damage_from_curve()
	_fire_angle_rad_delta = deg_to_rad(_fire_angle / _num_bullets)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	# Energy charm
	if _energy_did_damage:
		_owner_ultimate.current_cooldown_time -= _energy_charm_ult_time_reduction
	_energy_did_damage = false
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		var direction := Vector2.ZERO
		if _is_owned_by_player:
			var target = _find_nearest_target()
			if target != null:
				direction = global_position.direction_to(target.global_position)
			else:
				direction = Vector2.LEFT
		else:
			# Enemy bullet moves in direction of Enemy's desired velocity.
			direction = get_parent().velocity.normalized()
		
		direction = direction.rotated(deg_to_rad(-_fire_angle / 2.0))
		
		for i in range(_num_bullets):
			var crit: bool = randf() <= crit_chance
			var total_damage = bullet_damage * (1.0 if not crit else crit_multiplier)
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1, [_bullet_uid, 
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
			direction = direction.rotated(_fire_angle_rad_delta)
		
		# Play sound effect
		AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.CUPID_ARROW)
		
		# Signature quickly fires a second volley
		if signature_active and signature_direction_toggle == 0:
			shoot_timer = shoot_interval * 0.75
		else:
			shoot_timer = 0
		
		# Decide next volley direction
		if not signature_active:
			direction_toggle = !direction_toggle
		else:
			signature_direction_toggle += 1
			if signature_direction_toggle >= 2:
				direction_toggle = !direction_toggle
				signature_direction_toggle = 0


func activate_powerup():
	super()
	
	if _deactivation_sources > 0:
		return
	
	is_on = true
	if _is_owned_by_player:
		_owner_ultimate = get_parent().abilities[0]
	picked_up_powerup.emit()


func deactivate_powerup():
	super()
	is_on = false
	shoot_timer = 0.0


func level_up():
	current_level += 1
	bullet_damage = _get_damage_from_curve()
	
	if current_level >= 3:
		_num_bullets = 10
		_fire_angle_rad_delta = deg_to_rad(_fire_angle / _num_bullets)
		shoot_interval = shoot_interval * 0.9

	if is_signature and current_level == max_level:
		signature_active = true
		shoot_interval = 0.5
	powerup_level_up.emit(current_level, bullet_damage)


func boost() -> void:
	shoot_interval /= 2.0


func unboost() -> void:
	shoot_interval *= 2.0


func boost_fire_rate() -> void:
	shoot_interval *= 0.75
