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
	MOTHER_NATURE,
	AZURE_JAY,
	LUNA,
	SAND_WITCH
}

enum Map {
	NONE,
	VALLEY,
	DESERT
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

## A condition which must be met in order to play a dialogue.
enum DialoguePlayCondition {
	NONE,
	MAP_VALLEY,
	MAP_DESERT,
	START,
	MINIBOSS_SPAWN,
	MINIBOSS_GOTH,
	MINIBOSS_SWEET,
	MINIBOSS_VALE,
	MINIBOSS_DOVE,
	MINIBOSS_DEFEATED,
	BOSS,
	WIN,
	MAP_ALIEN
}


## Paths for all the maps in the game. The order of maps in this array is the order in which
## they are displayed to the player.
const MAP_DATA: Array[MapData] = [
	preload("res://Levels/MapData/map_data_valley.tres"),
	preload("res://Levels/MapData/map_data_desert.tres"),
	preload("res://Levels/MapData/map_data_alien.tres")
]


# Maps character enum to their CharacterData resource file
var CHARACTER_DATA: Dictionary = {
	Character.GOTH: load("res://Player/CharacterResourceFiles/character_data_goth.tres"),
	Character.SWEET: load("res://Player/CharacterResourceFiles/character_data_sweet.tres"),
	Character.VALE: load("res://Player/CharacterResourceFiles/character_data_vale.tres"),
	Character.DOVE: load("res://Player/CharacterResourceFiles/character_data_dove.tres"),
	Character.MARIGOLD: load("res://Player/CharacterResourceFiles/character_data_marigold.tres"),
	Character.AMBER: load("res://Player/CharacterResourceFiles/character_data_amber.tres"),
	Character.MOTHER_NATURE: load("res://Player/CharacterResourceFiles/character_data_mothernature.tres"),
	#Character.AZURE_JAY: load("res://Player/CharacterResourceFiles/character_data_jay.tres"),
	#Character.LUNA: load("res://Player/CharacterResourceFiles/character_data_luna.tres"),
	#Character.SAND_WITCH: load("res://Player/CharacterResourceFiles/character_data_sandwitch.tres")
}
