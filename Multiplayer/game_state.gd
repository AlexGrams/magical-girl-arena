extends Node

# Manager class for the overall state of the game scene. 
# Controls spawning players and related functionality. 

const start_game_scene := "res://Levels/playground.tscn"
const player_scene := "res://Player/player_character_body.tscn"
const level_exp_needed: Array = [10, 10, 10, 10, 10, 10]

# Unordered list of instantiated player characters in the game
var player_characters = []
# Experience to next level
var experience: float = 0.0
# Current level
var level: int = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Set up the shooting portion of the game. Switches the scene and loads the players.
func start_game():
	assert(multiplayer.is_server())
	load_game.rpc()
	
	var player_resource := load(player_scene)
	
	# Spawn each player at a spawn point.
	var spawn_point_index = 0
	for player_id in MultiplayerManager.player_ids:
		var player: CharacterBody2D	 = player_resource.instantiate()
		player.set_label_name(str(player_id))
		get_tree().root.get_node("Playground").add_child(player, true)
		
		# Get the player's view to only follow this character
		player.set_camera_current.rpc_id(player_id)
		
		# Players need to be given authority over their characters, and other players
		# need to have authority set locally for each remote player.
		player.set_authority.rpc(player_id)
		player.ready_local_player.rpc_id(player_id)
		
		var spawn_point: Vector2 = get_tree().root.get_node("Playground/PlayerSpawnPoints").get_child(spawn_point_index).position
		player.teleport.rpc_id(player_id, spawn_point)
		spawn_point_index += 1


# Add a player character to local list of spawned characters
func add_player_character(new_player: CharacterBody2D) -> void:
	player_characters.append(new_player)


# Load the main game scene and hide the menu.
@rpc("authority", "call_local", "reliable")
func load_game():
	var world = load(start_game_scene).instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("MainMenu").hide()

	get_tree().set_pause(false) 


# Add exp to all players. Only call on the server.
@rpc("any_peer", "call_local")
func collect_exp() -> void:
	experience += 1
	if level < level_exp_needed.size() and experience >= level_exp_needed[level-1]:
		experience -= level_exp_needed[level-1]
		level += 1
		# TODO: Do something about replicating shoot interval
		#shoot_interval = level_shoot_intervals[level]
		
		# Show upgrade screen
		get_tree().paused = true
		get_tree().get_root().get_node("Playground/CanvasLayer/UpgradeScreenPanel").show()
	
	for player in player_characters:
		player.emit_gained_experience(experience, level)
