class_name MapData
extends Resource
## Stores important properties for each map.


## Name of this map as displayed to the player.
@export var name: String = ""
## Path to the scene to load for this map.
@export var scene_path: String = ""
## The dialogue play condition specfic to this map.
@export var map_dialogue_condition: Constants.DialoguePlayCondition = Constants.DialoguePlayCondition.NONE
