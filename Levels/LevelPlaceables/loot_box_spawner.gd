class_name LootBoxSpawner
extends AreaSpawner


## The most times that we will attempt to generate a random position that isn't near a player.
const MAX_POSITION_CHECKS: int = 30
## At least how far the LootBox will be spawned from any player. Prevents the LootBox from spawning on top of someone.
const MIN_DISTANCE_FROM_NEAREST_PLAYER: float = 400.0
## The radius of the physics query used to determine if the chosen spawn location collides with obstacles.
## Should be at least as big as the size of a LootBox.
const COLLISION_CHECK_RADIUS: float = 100.0

## Time in seconds between spawning LootBoxes
@export var spawn_interval: float = 1.0
@export var loot_box_scene: PackedScene = null

var _time: float = 0.0
var _min_distance_squared
## Used to see if the randomly generated position to spawn a lootbox is colliding with a map obstacle.
var _spawn_collision_check_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	super()
	
	_min_distance_squared = MIN_DISTANCE_FROM_NEAREST_PLAYER * MIN_DISTANCE_FROM_NEAREST_PLAYER
	
	_spawn_collision_check_params.collide_with_areas = false
	_spawn_collision_check_params.collide_with_bodies = true
	# The 8th layer/7th bit is the "obstacle" collision layer
	_spawn_collision_check_params.collision_mask = 1 << 7
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = COLLISION_CHECK_RADIUS
	_spawn_collision_check_params.shape = circle_shape


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_time += delta
	if _time >= spawn_interval:
		# Attempt to spawn a LootBox at a random position, but not too close to any player.
		# Although rare, we limit the amount of random positions generated this frame so that the game doens't 
		# hang for a while in case we keep generating bad positions. In this case, we wait until next frame to 
		# try spawning the LootBox again.
		var found_good_position = false
		var spawn_pos = Vector2.ZERO
		var checks = 0
		
		while not found_good_position and checks < MAX_POSITION_CHECKS:
			found_good_position = true
			spawn_pos = Vector2(
				randf_range(_spawn_x_min, _spawn_x_max), 
				randf_range(_spawn_y_min, _spawn_y_max)
			)
			
			# See if the random position is too close to a player.
			for player: PlayerCharacterBody2D in GameState.player_characters.values():
				if player.position.distance_squared_to(spawn_pos) < _min_distance_squared:
					found_good_position = false
					break
			
			# See if the random position is colliding with obstacles.
			if found_good_position:
				var space_state = get_world_2d().direct_space_state
				_spawn_collision_check_params.transform = Transform2D(0.0, spawn_pos)
				if not space_state.intersect_shape(_spawn_collision_check_params, 1).is_empty():
					found_good_position = false
			
			checks += 1
		
		if found_good_position:
			# We found a valid position before running out of checks this frame, so spawn the LootBox.
			var loot_box: LootBox = loot_box_scene.instantiate()
			get_node("..").add_child(loot_box, true)
			loot_box.teleport.rpc(spawn_pos)
			_time = 0.0


## Do not call. Does nothing. LootBox is spawned in _process rather than through the spawn() function.
func spawn(_scene_to_spawn: PackedScene) -> Node2D:
	return null
