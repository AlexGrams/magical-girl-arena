extends Bullet
## Moves in variety of sinusoidal patterns before exploding at its destination.

var _timer: float = 0.0
var _starting_direction: Vector2 = Vector2.ZERO
var _starting_rotation: float = 0.0
var _distance: float = 0.0


func _ready() -> void:
	_starting_direction = direction
	_starting_rotation = Vector2.LEFT.angle_to(direction)
	## TODO: Set in setup_bullet
	_distance = randf_range(250.0, 750.0)
	lifetime = _distance / speed
	
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.REVOLVING)


func _process(delta: float) -> void:
	#global_position += direction * speed * delta
	death_timer += delta
	
	# For testing, 2PI is a complete cycle.
	_timer += (delta / lifetime) * 2 * PI
	direction = Vector2(1.0, cos(_timer)).normalized().rotated(_starting_rotation)
	global_position += direction * speed * delta
	
	# TODO: Somehow the rotation equation is off.
	#rotation_degrees = rad_to_deg(Vector2.UP.angle_to(direction))
	
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	# TODO: Probably don't want to do anything here. Not really intending for this to be used by Enemies.
	if not is_multiplayer_authority():
		return
	
	if _is_owned_by_player:
		# Player's bullets should be destroyed when they hit something if applicable.
		if destroy_on_hit:
			queue_free()
	else:
		# Enemy's bullets should deal damage if they hit a player's bullet.
		# NOTE: Enemy bullets are deleted when the character that they hit calls an RPC to delete them.
		if area is BulletHitbox:
			take_damage(area.damage)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	# Make the bullet hurt players
	if not is_owned_by_player:
		_is_owned_by_player = false
		_health = max_health
		_modify_collider_to_harm_players()
