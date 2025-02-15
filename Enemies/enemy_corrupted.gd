class_name EnemyCorrupted
extends EnemyRanged
# A corrupted magical girl enemy. Can use powerups and abilities like the player.


func _ready() -> void:
	super()


func _physics_process(delta: float) -> void:
	super(delta)


func shoot() -> void:
	var direction = target.global_position - self.global_position
	direction = direction.normalized()

	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [null, 
			global_position, 
			direction, 
			bullet_damage, 
			[]
		]
	)
