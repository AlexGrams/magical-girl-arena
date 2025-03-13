extends Node
# Contains properties accessible everywhere in the game.

## Collision layer for a bullet to be able to damage players.
const ENEMY_BULLET_COLLISION_LAYER: int = 6
## Collision mask for a bullet to be able to damage players.
const ENEMY_BULLET_COLLISION_MASK: int = 4

enum Character {
	GOTH,
	SWEET,
	NONE = -1
}

enum EnemySpriteType {
	STANDARD,
	SPECIAL,
	GOTH_ALLY
}
