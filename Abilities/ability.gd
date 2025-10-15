class_name Ability
extends Node2D
## Base class for all Abilities. An Ability is a mechanic that is activated by the player
## by pressing a button. This is different from a Powerup, which is always active.
## Ability objects are not replicated and only spawn on the client player that owns 
## the ability. Use RPCs to notify other clients of the effects of using an Ability.
##
## Code flow:
## 1. Player does input to do an ability
## 2. Ability.activate() is called
## 3. The ability cannot be activated again until the cooldown is done.

# Time in seconds when this Ability cannot be activated again.
@export var cooldown: float = 0.0

var current_cooldown_time: float = 0.0

## Chance of critical damage as a fraction. 1.0 is guaranteed critical.
var _crit_chance: float = 0.0

## Emitted every time current_cooldown_time is updated.
signal cooldown_time_updated(cooldown_time_remaining_fraction: float)


func get_can_activate() -> bool:
	return current_cooldown_time <= 0.0


# Set the multiplayer authority for this ability
func set_authority(id: int) -> void:
	set_multiplayer_authority(id)


func set_crit_chance(value: float) -> void:
	_crit_chance = value


## Modifies the amount of cooldown time remaining.
func reduce_current_cooldown(amount: float) -> void:
	current_cooldown_time = clamp(current_cooldown_time - amount, 0.0, cooldown)
	cooldown_time_updated.emit(current_cooldown_time / cooldown)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start with the ability ready to use.
	cooldown_time_updated.emit(0)
	update_damage(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_cooldown_time > 0.0:
		reduce_current_cooldown(delta)


# Start this Ability's functionality.
func activate() -> void:
	current_cooldown_time = cooldown


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	pass
