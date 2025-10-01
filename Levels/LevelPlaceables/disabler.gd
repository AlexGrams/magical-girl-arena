class_name Disabler
extends DestructibleNode2D
## A Node that disables all powerups except those of a certain type when a player is nearby.


## The type of powerups that aren't affected by this Disabler.
var _allow_type: Powerup.Type = Powerup.Type.NULL


func _ready() -> void:
	super()
	_allow_type = randi_range(1, Powerup.Type.size() - 1) as Powerup.Type


func _on_area_2d_entered(area: Area2D) -> void:
	super(area)


## Disable all powerups that aren't of a certain type on the local player.
func _on_disable_area_2d_area_entered(area: Area2D) -> void:
	var other = area.get_parent()
	
	if other != null and other == GameState.get_local_player():
		var player: PlayerCharacterBody2D = other
		for powerup: Powerup in player.powerups:
			if not powerup.has_type(_allow_type):
				powerup.deactivate_powerup()


func _on_disable_area_2d_area_exited(area: Area2D) -> void:
	var other = area.get_parent()
	
	if other != null and other == GameState.get_local_player():
		var player: PlayerCharacterBody2D = other
		for powerup: Powerup in player.powerups:
			if not powerup.has_type(_allow_type):
				powerup.activate_powerup()
