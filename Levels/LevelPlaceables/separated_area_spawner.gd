class_name SeparatedAreaSpawner
extends AreaSpawner
## Spawns a scene periodically where each object is at least a certain distance from 
## objects on a set of collision layers.


## The most times that we will attempt to generate a random position that isn't near a player.
const MAX_POSITION_CHECKS: int = 30

## Time in seconds between spawning objects.
@export var spawn_interval: float = 1.0
@export var spawn_object_scene: PackedScene = null

## Minimum spawn distance from the player
@export var _min_distance_from_nearest_player: float = 400.0
## The radius of the physics query used to determine if the chosen spawn location collides with obstacles.
## Should be at least as big as the size of the spawned object.
@export var _collision_check_radius: float = 100.0

var _time: float = 0.0
var _min_distance_squared
## Used to see if the randomly generated position to spawn a object is colliding with a map obstacle.
var _spawn_collision_check_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	super()
	
	_min_distance_squared = _min_distance_from_nearest_player ** 2
	
	_spawn_collision_check_params.collide_with_areas = false
	_spawn_collision_check_params.collide_with_bodies = true
	# The 8th layer/7th bit is the "obstacle" collision layer
	_spawn_collision_check_params.collision_mask = 1 << 7
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = _collision_check_radius
	_spawn_collision_check_params.shape = circle_shape


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_time += delta
	if _time >= spawn_interval:
		# Attempt to spawn a object at a random position, but not too close to any player.
		# Although rare, we limit the amount of random positions generated this frame so that the game doens't 
		# hang for a while in case we keep generating bad positions. In this case, we wait until next frame to 
		# try spawning the object again.
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
			# We found a valid position before running out of checks this frame, so spawn the object.
			var spawned_node: Node2D = spawn_object_scene.instantiate()
			get_node("..").add_child(spawned_node, true)
			spawned_node.teleport.rpc(spawn_pos)
			_time = 0.0


## Do not call. Does nothing. Object is spawned in _process rather than through the spawn() function.
func spawn(_scene_to_spawn: PackedScene) -> Node2D:
	return null
