class_name Powerup
extends Node2D
## Abstract class for abilities granted to the player. 
## Powerups are not replicated, but their effects are. The powerup scene only exists on the 
## client that owns the powerup, but stuff like spawning bullets or applying buffs should be done 
## using RPCs so that this Powerup's functionality is seen on all clients.
## TODO: Probably need to make this class utilize the PowerData resource for setting some of
## its properties.
## TODO: Maybe also change the script name to match capitalization scheme.

## The highest level that this powerup can be upgraded to.
const max_level: int = 5

## Curve describing how this powerup's main stat changes as it is upgraded.
@export var upgrade_curve: Curve = null
## Name used to uniquely identify this Powerup.
@export var powerup_name := ""

## What level the powerup is at. Values are [1, max_level].
var current_level: int = 1
var damage_levels: Array
## True when this Powerup is active, which usually means it is shooting bullets.
var is_on: bool = false

# True when this powerup harms enemies, false when it harms players.
var _is_owned_by_player := true

# Emitted after increasing this Powerup's level
signal powerup_level_up(new_level: int, new_damage: float)


func set_is_owned_by_player(value: bool) -> void:
	_is_owned_by_player = value


# Meant to be overridden
func level_up():
	powerup_level_up.emit(0, 0)
	push_error("Powerup.level_up(): THIS SHOULD NOT BE ACTIVATING.")


func activate_powerup():
	push_error("Powerup.activate_powerup(): THIS SHOULD NOT BE ACTIVATING.")


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	push_error("Powerup.deactivate_powerup(): THIS SHOULD NOT BE ACTIVATING.")


# Set the multiplayer authority for this powerup
func set_authority(id: int) -> void:
	set_multiplayer_authority(id)


## Calculates this powerup's damage given its current level using the upgrade curve.
func _get_damage_from_curve() -> float:
	return upgrade_curve.sample(float(current_level - 1) / (max_level - 1))
