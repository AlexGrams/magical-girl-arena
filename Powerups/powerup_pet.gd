extends Powerup
## Might be unique in that this powerup doesn't create a Bullet.


## UID of the pet scene bullet.
var pet_scene := "uid://npslgflisq38"
## The single pet bullet instance used by this Powerup. Only destroyed when the player goes down.
var pet: BulletPet


func _ready():
	super()


func activate_powerup():
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
	else:
		# TODO: Support for when owned by an enemy.
		pass


# Does nothing. The bullet destroys itself based off of the player's "died" signal.
func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())


func boost() -> void:
	if pet != null:
		pet.boost()


func unboost() -> void:
	if pet != null:
		pet.unboost()


func boost_fire_rate() -> void:
	if pet != null:
		pet.boost()
