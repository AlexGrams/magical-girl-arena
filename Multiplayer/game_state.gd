extends Node

# Manager class for the overall state of the game scene. 
# Controls spawning players and related functionality. 

const start_game_scene := "res://Levels/playground.tscn"
const player_scene := "res://Player/player_character_body.tscn"

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
		print("Spawned " + str(player_id))
		
		# Players need to be given authority over their characters, and other players
		# need to have authority set locally for each remote player.
		player.set_authority.rpc(player_id)
		
		var spawn_point: Vector2 = get_tree().root.get_node("Playground/PlayerSpawnPoints").get_child(spawn_point_index).position
		player.teleport.rpc_id(player_id, spawn_point)
		spawn_point_index += 1


# Load the main game scene and hide the menu.
@rpc("authority", "call_local", "reliable")
func load_game():
	var world = load(start_game_scene).instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("MainMenu").hide()

	get_tree().set_pause(false) 
