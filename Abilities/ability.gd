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

var currentCooldownTime: float = 0.0


func get_can_activate() -> bool:
	return currentCooldownTime <= 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if currentCooldownTime > 0.0:
		currentCooldownTime -= delta


# Start this Ability's functionality.
func activate() -> void:
	currentCooldownTime = cooldown
