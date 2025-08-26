class_name StatusAmberUlt
extends Status
## Boosts owneing player's speed and powerups for the duration that this status is applied.


var _owning_player: PlayerCharacterBody2D = null
var _fire_vfx: Resource = load("res://Sprites/fire.tscn")
var fire:Sprite2D


func get_status_name() -> String:
	return "AmberUlt"


## Start this status effect's functionality. Only call after adding this as a child to the object
## that this status affects.
func activate() -> void:
	if get_parent() is PlayerCharacterBody2D:
		_owning_player = get_parent()
		for powerup: Powerup in _owning_player.powerups:
			powerup.boost()
		
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		_owning_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)
		
		# Add fire visual
		fire = _fire_vfx.instantiate()
		# Position and scale are just hard coded after testing on character_animated_sprite
		var sprite = _owning_player._character_animated_sprite
		fire.scale = Vector2(400, 500)
		fire.position = Vector2(0, -sprite.texture.get_height()/8.0)
		fire.z_index = -1
		sprite.add_child(fire)


## Get rid of the effects of this status.
func deactivate() -> void:
	if _owning_player != null:
		for powerup: Powerup in _owning_player.powerups:
			powerup.unboost()
		
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_owning_player.decrement_stat(Constants.StatUpgrades.SPEED)
		
		_owning_player._character_animated_sprite.remove_child(fire)
