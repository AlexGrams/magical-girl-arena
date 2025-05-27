class_name LootBoxSpawner
extends AreaSpawner


## The most times that we will attempt to generate a random position that isn't near a player.
const MAX_POSITION_CHECKS: int = 30
## At least how far the LootBox will be spawned from any player. Prevents the LootBox from spawning on top of someone.
const MIN_DISTANCE_FROM_NEAREST_PLAYER: float = 400.0

## Time in seconds between spawning LootBoxes
@export var spawn_interval: float = 1.0
@export var loot_box_scene: PackedScene = null

var _time: float = 0.0
var _min_distance_squared


func _ready() -> void:
	super()
	
	_min_distance_squared = MIN_DISTANCE_FROM_NEAREST_PLAYER * MIN_DISTANCE_FROM_NEAREST_PLAYER


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
			for player: PlayerCharacterBody2D in GameState.player_characters.values():
				if player.position.distance_squared_to(spawn_pos) < _min_distance_squared:
					found_good_position = false
					break
			
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
