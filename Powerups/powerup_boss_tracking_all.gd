extends PowerupBossTracking
## Fires at all players instead of just one.


func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > _shoot_interval:
		if _is_owned_by_player:
			# Not implemented for use with Players.
			push_warning("Not implemented!")
		
		for player: PlayerCharacterBody2D in GameState.player_characters.values():
			var direction: Vector2 = (player.global_position - global_position).normalized() 
			var bullet_position := self.global_position + (direction * 100)
			
			GameState.playground.bullet_spawner.request_spawn_bullet.rpc_id(
				1, 
				[
					_bullet_scene, 
					bullet_position, 
					direction, 
					_bullet_damage, 
					false,
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[]
				]
			)
		
		_shoot_timer = 0
