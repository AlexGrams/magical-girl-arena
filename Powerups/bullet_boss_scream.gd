extends Bullet
## Damages all players on the map that aren't behind a terrain obstacle. Destroys all
## BulletBossTerrain objects.


## Time between bullet spawning and dealing damage.
@export var _tell_time: float = 2.0
## Visual for the scream. 
## Light source allows it to be blocked by terrain with LightOccluder2Ds
@export var _point_light: PointLight2D

var _tell_timer: float = 0.0


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	if _tell_timer > 0.0:
		# Stage 1: Warn that the attack is coming.
		_tell_timer -= delta
		if _tell_timer <= 0.0:
			# Stage 2: Deal damage.
			print("Scream!")
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_property(_point_light, "energy", 16, 0.0001)
			# Attempt to damage the local player.
			var local_player: PlayerCharacterBody2D = GameState.get_local_player()
			var query := PhysicsRayQueryParameters2D.create(
				global_position, 
				local_player.global_position
			)
			
			# Set the collision to only hit terrain object and the local player.
			query.collide_with_bodies = true
			query.collide_with_areas = true
			query.collision_mask = 1 << 3	# player collision layer
			query.collision_mask += 1 << 7	# obstacle
			# Characters that aren't the local player need to be specifically excluded.
			var exclude_rids: Array[RID] = []
			for player: PlayerCharacterBody2D in GameState.player_characters.values():
				if player != local_player:
					exclude_rids.append(player.get_player_collision_area().get_rid())
			query.exclude = exclude_rids
			
			var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
			if not result.is_empty() and result["collider"].get_parent() == local_player:
				# The attack has hit the local player.
				local_player.take_damage(collider.damage)
			
			# From the server, destroy all terrain bullets.
			# TODO: Don't actually destroy all the terrain bullets at the same time as the 
			# scream damage going off, as it is possible for the bullet to be destroyed on
			# clients before the collision check, meaning clients could get hit even though
			# they were behind a terrain.
			if is_multiplayer_authority():
				get_tree().call_group("bullet_boss_terrain", "destroy")
				tween.tween_property(_point_light, "energy", 0, 0.25)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (len(data) != 0
	):
		push_error("Malformed Bullet setup")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	if not is_owned_by_player:
		_tell_timer = _tell_time
