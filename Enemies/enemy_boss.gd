class_name EnemyBoss
extends Enemy
## A special enemy that ends the game when it is defeated.


func _physics_process(delta: float) -> void:
	super(delta)
