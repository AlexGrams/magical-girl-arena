class_name BulletHitbox
extends Area2D

## How much damage this bullet does.
@export var damage: float

## The multiplayer ID of the player that owns this bullet, if any. -1 if player does not. Used for analytics.
var owner_id: int = -1
## The index of the powerup that created this bullet if it is owned by the player. -1 if it wasn't created
## by a player's powerup. Used for analytics.
var powerup_index: int = -1
