class_name Powerup
extends Node2D
## Abstract class for abilities granted to the player. 
## Powerups are not replicated, but their effects are. The powerup scene only exists on the 
## client that owns the powerup, but stuff like spawning bullets or applying buffs should be done 
## using RPCs so that this Powerup's functionality is seen on all clients.
## TODO: Probably need to make this class utilize the PowerData resource for setting some of
## its properties.
## TODO: Maybe also change the script name to match capitalization scheme.

## Tags used to describe different Powerups.
enum Type {
	NULL,
	ProjectileFireRate,
	Haste,
	AreaSize,
	Critical,
	Energy
}

## The highest level that this powerup can be upgraded to.
const max_level: int = 5

## How much damage this Powerup does at each level that its upgraded to.
@export var damage_levels: Array[float] = [0, 0, 0, 0, 0]
## How much damage this Powerup does at max level as a signature Powerup.
@export var signature_damage: float = 0.0

## Path to this Powerup's PowerupData.
@export var _powerup_data_path: String = ""

## Name used to uniquely identify this Powerup.
var powerup_name := ""
## What level the powerup is at. Values are [1, max_level].
var current_level: int = 1
## True if the owning player has access to this Powerup's signature behavior when it reaches max level.
var is_signature: bool = false
## True when this Powerup is active, which usually means it is shooting bullets.
var is_on: bool = false
## How likely this powerup is to crit, expressed as a fraction from 0.0 to 1.0.
var crit_chance: float = 0.0
## Base damage is multiplied by this number to get the new damage amount when this powerup crits.
var crit_multiplier: float = 2.0

## Loaded PowerupData resource file.
var _powerupdata: PowerupData = null
# True when this powerup harms enemies, false when it harms players.
var _is_owned_by_player := true
## The index of this powerup in the player's array of powerups, if this is owned by a player.
var _powerup_index: int = -1
## Collection of tags used to describe this Powerup.
var _types: Array[Type] = []

# Emitted after increasing this Powerup's level
signal powerup_level_up(new_level: int, new_damage: float)


func get_types() -> Array[Type]:
	return _types


func set_is_owned_by_player(value: bool) -> void:
	_is_owned_by_player = value


func set_is_signature(value: bool) -> void:
	is_signature = value


func set_powerup_index(index: int) -> void:
	_powerup_index = index


## Can be overridden to do extra functionality when crit chance changes
func set_crit_chance(new_crit: float) -> void:
	crit_chance = new_crit


func set_crit_multiplier(new_multiplier: float) -> void:
	crit_multiplier = new_multiplier


## Give this Powerup an additional type.
func add_type(type: Type) -> void:
	_types.append(type)
	_powerupdata.types.append(type)
	GameState.playground.hud_canvas_layer.update_information_panel(_powerupdata)


## Returns true if this Powerup is a certain type.
func has_type(type: Type) -> bool:
	return _types.has(type)


func _ready() -> void:
	if _powerup_data_path != "":
		_powerupdata = load(_powerup_data_path).duplicate()
		powerup_name = _powerupdata.name
		_types = _powerupdata.types


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


## Temporarily increase the functionality of this Powerup.
func boost() -> void:
	pass


## Return this Powerup to normal functionality after it has been boosted.
func unboost() -> void:
	pass


## A boost specific to Fire Rate Powerups.
func boost_fire_rate() -> void:
	push_error("Fire rate boost not implemented for " + powerup_name)


## A boost for Powerups with the "Haste" type.
func boost_haste() -> void:
	push_error("Haste boost not implemented for " + powerup_name)


## A boost for Powerup with the "Energy" type.
func boost_energy() -> void:
	push_error("Energy boost not implemented for " + powerup_name)


# Set the multiplayer authority for this powerup
func set_authority(id: int) -> void:
	set_multiplayer_authority(id)


## Calculates this powerup's damage given its current level using the upgrade curve.
func _get_damage_from_curve() -> float:
	if current_level > len(damage_levels):
		push_error("Not enough damage levels to get the damage of this powerup")
		return 0
	elif current_level == len(damage_levels) and is_signature:
		return signature_damage
	else:
		return damage_levels[current_level - 1]


## Returns Node2D or null of the target nearest to the Powerup owner.
func _find_nearest_target() -> Node2D: 
	if _is_owned_by_player:
		# Get nearest enemy so direction can be set
		var enemies: Array[Node] = [] 
		enemies = get_tree().get_nodes_in_group("enemy")
		
		if !enemies.is_empty():
			var nearest_enemy = enemies[0]
			var nearest_distance = global_position.distance_squared_to(enemies[0].global_position)
			for enemy in enemies:
				var distance = global_position.distance_squared_to(enemy.global_position)
				if distance < nearest_distance:
					nearest_enemy = enemy
					nearest_distance = distance
			return nearest_enemy
	else:
		push_warning("Not implemented for enemies")
	return null
