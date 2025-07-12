class_name DialogueLine
extends Resource
## Information for one line of dialogue.

## Who is speaking this line.
@export var speaker: Constants.Character = Constants.Character.NONE
## Text that is displayed for this line.
@export var dialogue: String = ""
## [Optional] Portrait for Constants.Character.None speakers
@export var optional_portrait: Texture2D = null
