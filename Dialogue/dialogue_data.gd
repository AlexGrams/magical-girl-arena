class_name DialogueData
extends Resource
## All information for one dialogue sequence. Has multiple lines of dialogue and the conditions necessary
## to play the dialogue.

## All parts of this dialogue.
@export var lines: Array[DialogueLine] = []
## At what point in the game can this dialogue be played. 
@export var play_trigger: Constants.DialoguePlayTrigger = Constants.DialoguePlayTrigger.NONE
