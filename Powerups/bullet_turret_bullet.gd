class_name BulletTurretBullet
extends Bullet
## Bullet that is shot by turrets.
## Designed to allow for additional level 3 upgrade effects

## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_BOOL 	# Level 3 upgrade or not
	):
		push_error("Malformed data array")
		return

	# Level 3 upgrade - increase in size
	if data[0]:
		scale = scale * 2
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		_is_owned_by_player = false
		_health = max_health
		_modify_collider_to_harm_players()
