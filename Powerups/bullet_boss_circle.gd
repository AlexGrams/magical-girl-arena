class_name BulletBoss
extends BulletEnemy
## A simple, indestructible bullet shot by bosses.


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	if not is_owned_by_player:
		# Make the bullet hurt players and indestructible.
		_is_owned_by_player = false
		if sprite != null:
			sprite.self_modulate = Color.RED
