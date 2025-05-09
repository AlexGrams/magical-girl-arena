class_name CharacterData
extends Resource

## Name as it will appear whenever displayed to the player
@export var name: String
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
## Multiplied to the base scale to ensure all characters are the same size, since model sizes vary
@export var model_scale_multiplier: float = 1
## Path to the .tscn file for this character's ultimate ability.
@export var ultimate_ability: String
## UID of the small icon image representing this character. 
@export var icon_uid: String
