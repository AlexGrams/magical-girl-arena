class_name StatusPuddle
extends Status
## Status effect applied by the Puddle powerup to allies that touch puddle bullets. Increases speed
## and health regen slightly. Effect does not stack, but the duration is refreshed while a player
## is touching a puddle.

## How many speed increments to make
const SPEED_AMOUNT: int = 5
## How long this status lasts
var lifetime: float
## Owning player
var _player: PlayerCharacterBody2D = null
## How long it has been since the last speed decrement
var _speed_decay_counter: float = 0
## Tracks how many speed decrements have been made. 
## Should match SPEED_AMOUNT before it's been deactivated
var _total_decay_count: int = 0


func get_status_name() -> String:
	return "Puddle"


func _ready() -> void:
	super()
	lifetime = duration


func _process(delta: float) -> void:
	super(delta)
	## Speed boost depletes over time, rather than suddenly
	_speed_decay_counter += delta
	# (SPEED_AMOUNT / lifetime) evenly decays the speed
	print(SPEED_AMOUNT / lifetime)
	if _speed_decay_counter >= (SPEED_AMOUNT / lifetime):
		_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_total_decay_count += 1
		_speed_decay_counter = 0
	


## Temporarily boost owning player's speed and health regen.
func activate() -> void:
	_player = get_parent()
	for _i in range(SPEED_AMOUNT):
		_player._on_stat_upgrade_chosen(Constants.StatUpgrades.SPEED)


## Revert speed and health regen changes.
func deactivate() -> void:
	#for _i in range(SPEED_AMOUNT):
		#_player.decrement_stat(Constants.StatUpgrades.SPEED)
	# If the speed boost hasn't ended already, then end it now.
	while _total_decay_count < SPEED_AMOUNT:
		_player.decrement_stat(Constants.StatUpgrades.SPEED)
		_total_decay_count += 1
	_player.remove_status(self)
