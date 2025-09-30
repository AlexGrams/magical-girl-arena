class_name PowerupPet
extends Powerup
## Might be unique in that this powerup doesn't create a Bullet.


## UID of the pet scene bullet.
var pet_scene := "uid://npslgflisq38"
## The single pet bullet instance used by this Powerup. Only destroyed when the player goes down.
var pet: BulletPet


func set_pet(new_pet: BulletPet) -> void:
	pet = new_pet
	if _area_size_boosted:
		pet.boost_area_size.rpc()


func _ready():
	super()


func activate_powerup():
	super()
	
	if _deactivation_sources <= 0:
		if _is_owned_by_player:
			get_parent().spawn_pet_and_set_up.rpc_id(
				1, 
				pet_scene, 
				get_parent().get_path(), 
				global_position, 
				_get_damage_from_curve(),
				multiplayer.get_unique_id(),
				_powerup_index,
				current_level
			)
			if _area_size_boosted:
				boost_area_size()
		else:
			# TODO: Support for when owned by an enemy.
			pass


func deactivate_powerup():
	super()
	# TODO: Fix?


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	if pet != null:
		pet.boost.rpc()


func unboost() -> void:
	if pet != null:
		pet.unboost.rpc()


func boost_haste() -> void:
	if pet != null:
		pet.boost.rpc()


func boost_area_size() -> void:
	super()
	if pet != null:
		pet.boost_area_size.rpc()
