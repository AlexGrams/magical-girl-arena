class_name CharacterData
extends Resource

## Name as it will appear whenever displayed to the player and for animations
@export var name: String
## Name as it will appear whenever displayed to the player, if differ from name
@export var display_name: String = ""
## The character's lore
@export var description: String
## Path to the PowerupData for this character's base Powerup.
@export var base_powerup_data: String
## The name of this character's starting powerup.
@export var base_powerup_name: String
## Image representing the starting powerup.
@export var base_powerup_texture: Texture2D
## The name of this character's ultimate ability.
@export var ult_name: String
## Description of how this character's ultimate works.
@export var ult_description: String
## Image representing the ultimate ability.
@export var ult_texture: Texture2D
## Path to the .json file for this character's GDCubism sprite. 
@export var model_file_path: String
## Corrupted version of the model_file_path.
@export var corrupted_model_file_path: String
## Multiplied to the base scale to ensure all characters are the same size, since model sizes vary
@export var model_scale_multiplier: float = 1
## Offset for y value to make sure feet are in the correct spot compared to all characters
@export var offset_height: float = 0
## Path to the .tscn file for this character's ultimate ability.
@export var ultimate_ability: String
## UID of the small icon image representing this character. 
@export var icon_uid: String
## The name of the boolean variable in GameState that is true if this character is playable, if any.
@export var character_unlocked_variable_name: String


## Returns true if this character is unlocked.
func get_is_unlocked() -> bool:
	return (
		character_unlocked_variable_name == "" 
		or GameState.get(character_unlocked_variable_name)
	)
