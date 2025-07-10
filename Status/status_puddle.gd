class_name StatusPuddle
extends Status
## Status effect applied by the Puddle powerup to allies that touch puddle bullets. Increases speed
## and health regen slightly. Effect does not stack, but the duration is refreshed while a player
## is touching a puddle.


## Owning player
var _player: PlayerCharacterBody2D = null


func get_status_name() -> String:
	return "Puddle"


func _ready() -> void:
	super()


func _process(delta: float) -> void:
	super(delta)


## Temporarily boost owning player's speed and health regen.
func activate() -> void:
	_player = get_parent()
	_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)


## Revert speed and health regen changes.
func deactivate() -> void:
	_player.decrement_stat(Constants.StatUpgrades.SPEED)
	_player.remove_status(self)
