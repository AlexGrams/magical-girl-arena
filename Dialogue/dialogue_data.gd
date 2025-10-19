class_name DialogueData
extends Resource
## All information for one dialogue sequence. Has multiple lines of dialogue and the conditions necessary
## to play the dialogue.

## All parts of this dialogue.
@export var lines: Array[DialogueLine] = []
## At what point in the game can this dialogue be played. 
@export var play_conditions: Array[Constants.DialoguePlayCondition] = []
## Characters that have no lines but must also be present in order to play this dialogue.
@export var _extra_characters: Array[Constants.Character] = []


## Returns list of characters that participate in this dialogue.
func get_characters() -> Array[Constants.Character]:
	var result: Array[Constants.Character] = _extra_characters
	for line: DialogueLine in lines:
		if line.speaker not in result:
			result.append(line.speaker)
	return result
