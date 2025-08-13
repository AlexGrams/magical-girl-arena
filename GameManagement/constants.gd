extends Node
# Contains properties accessible everywhere in the game.

## Collision layer for a bullet to be able to damage players.
const ENEMY_BULLET_COLLISION_LAYER: int = 6
## Collision masks for a bullet to be able to damage players.
const ENEMY_BULLET_COLLISION_MASK: Array[int] = [1, 4]

enum Character {
	NONE = -1,
	GOTH,
	SWEET,
	VALE,
	DOVE,
	MARIGOLD,
	AMBER,
	AZURE_JAY,
	MOTHER_NATURE,
	LUNA,
	SAND_WITCH
}

enum EnemySpriteType {
	STANDARD,
	SPECIAL,
	GOTH_ALLY
}

enum StatUpgrades {
	HEALTH,
	HEALTH_REGEN,
	SPEED,
	PICKUP_RADIUS
	# TODO: Implement when design is decided
	#DAMAGE,
	#ULTIMATE_DAMAGE,
	#ULTIMATE_CHARGE_RATE
}

## Different times throughout a game in which dialogue can play.
enum DialoguePlayTrigger {
	NONE,
	START,
	MINIBOSS,
	BOSS,
	WIN,
	MINIBOSS_DEFEATED
}

## An optional extra descriptor for a dialogue trigger. If not NONE, then this condition must also
## be met in order to play the dialogue.
enum DialoguePlayTriggerExtra {
	NONE,
	MINIBOSS_GOTH,
	MINIBOSS_SWEET,
	MINIBOSS_VALE,
	MINIBOSS_DOVE
}

# Maps character enum to their CharacterData resource file
var CHARACTER_DATA: Dictionary = {
	Character.GOTH: load("res://Player/CharacterResourceFiles/character_data_goth.tres"),
	Character.SWEET: load("res://Player/CharacterResourceFiles/character_data_sweet.tres"),
	Character.VALE: load("res://Player/CharacterResourceFiles/character_data_vale.tres"),
	Character.DOVE: load("res://Player/CharacterResourceFiles/character_data_dove.tres"),
	Character.MARIGOLD: load("res://Player/CharacterResourceFiles/character_data_marigold.tres"),
	Character.AMBER: load("res://Player/CharacterResourceFiles/character_data_amber.tres"),
	#Character.AZURE_JAY: load("res://Player/CharacterResourceFiles/character_data_jay.tres"),
	#Character.MOTHER_NATURE: load("res://Player/CharacterResourceFiles/character_data_mothernature.tres"),
	#Character.LUNA: load("res://Player/CharacterResourceFiles/character_data_luna.tres"),
	#Character.SAND_WITCH: load("res://Player/CharacterResourceFiles/character_data_sandwitch.tres")
}
