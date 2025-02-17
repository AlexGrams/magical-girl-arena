extends EnemyCorrupted


func shoot() -> void:
	pass
	#var direction = target.global_position - self.global_position
	#direction = direction.normalized()
	#
	#get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		#1, [scythe_bullet_scene_path, 
			#Vector2.ZERO, 
			#direction, 
			#bullet_damage, 
			#[get_path(), false]
		#]
	#)
