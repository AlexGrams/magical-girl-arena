extends Powerup
## Might be unique in that this powerup doesn't create a Bullet.


## UID of the pet scene bullet.
var pet_scene := "uid://npslgflisq38"
## The single pet bullet instance used by this Powerup. Only destroyed when the player goes down.
var pet: BulletPet


func _ready():
	pass


func activate_powerup():
	if _is_owned_by_player:
		var pet: BulletPet = load(pet_scene).instantiate()
		get_tree().root.get_node("Playground").add_child(pet, true)
		pet.global_position = global_position
		#get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			#1, [pet_scene, 
				#global_position, 
				#Vector2.UP, 
				#_get_damage_from_curve(), 
				#_is_owned_by_player,
				#[$"..".get_path()]
			#]
		#)
	else:
		# TODO: Support for when owned by an enemy.
		pass
		#get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			#1, [pet_scene, 
				#global_position, 
				#Vector2.UP, 
				#_get_damage_from_curve(), 
				#_is_owned_by_player,
				#[$"..".get_path()]
			#]
		#)


# Does nothing. The bullet destroys itself based off of the player's "died" signal.
func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, _get_damage_from_curve())
