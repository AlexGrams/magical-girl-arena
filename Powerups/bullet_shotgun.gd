extends Bullet


var _powerup_shotgun: PowerupShotgun = null


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	super(is_owned_by_player, _data)
	if is_owned_by_player:
		if multiplayer.get_unique_id() == collider.owner_id:
			_powerup_shotgun = GameState.get_local_player().get_node_or_null("PowerupShotgun")


func _on_area_2d_area_entered(area: Area2D) -> void:
	super(area)
	if _is_owned_by_player and area.get_parent() is Enemy:
		_powerup_shotgun.energy_did_damage()
