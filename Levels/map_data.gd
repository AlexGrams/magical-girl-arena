class_name MapData
extends Resource
## Stores important properties for each map.


## Name of this map as displayed to the player.
@export var name: String = ""
## Path to the scene to load for this map.
@export var scene_path: String = ""
## Image that shows on the Lobby for this map.
@export var preview_image_texture: Texture = null
## Name of the GameState variable that has to be true in order to unlock this map, if any.
@export var required_map_save_variable_name: String = ""
## The dialogue play condition specfic to this map.
@export var map_dialogue_condition: Constants.DialoguePlayCondition = Constants.DialoguePlayCondition.NONE
