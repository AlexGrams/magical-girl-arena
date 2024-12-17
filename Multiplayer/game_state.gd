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
	
	for peer_id in multiplayer.get_peers():
		print(peer_id)


# Load the main game scene.
@rpc("authority", "call_local", "reliable")
func load_game():
	get_tree().change_scene_to_file(start_game_scene)
