extends Node

# Manager class for the overall state of the game scene. 
# Controls spawning players and related functionality. 

# Should only be false in debugging builds.
const USING_GODOT_STEAM := true
# Max number of players. I believe this includes the server.
const MAX_PLAYERS: int = 4
const start_game_scene := "res://Levels/playground.tscn"
const player_scene := "res://Player/player_character_body.tscn"
const level_exp_needed: Array = [10, 10, 10, 10, 10, 10]

# The local player's name.
var player_name: String = ""
# TODO: Deprecate
# Unordered list of instantiated player characters in the game
var player_characters = []
# Map of player IDs to their names.
var players = {}
# The Steam lobby ID of the lobby that this player is in.
var lobby_id: int = 0
# Experience to next level
var experience: float = 0.0
# Current level
var level: int = 1
var players_selecting_upgrades: int = -1
# TODO: Figure out what this is for. Related to Godot Steam.
var peer: SteamMultiplayerPeer = null

signal player_list_changed()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("release") and not USING_GODOT_STEAM:
		push_error("Steam support is turned off! Ensure game_state.USING_GODOT_STEAM is true before making release build.")
		return
	
	# Set up Steam functionality
	if USING_GODOT_STEAM:
		Steam.steamInitEx(true, 480)
		
		if OS.has_feature("release") and Steam.getAppID() == 480:
			push_error("Release app ID was not changed from the testing value of 480! 
						Change it in game_state or make this a debug build.")
			return
		
		multiplayer.peer_connected.connect(
			func(id : int):
				# Tell the connected peer that we have also joined
				register_player.rpc_id(id, player_name)
		)
		
		multiplayer.peer_disconnected.connect(
			func(id : int):
				if false:#is_game_in_progress():
					# TODO: Handle disconnecting while in a game
					pass
					#if multiplayer.is_server():
						#game_error.emit("Player " + players[id] + " disconnected")
						#end_game()
				else:
					# Player disconnected while on the lobby screen.
					unregister_player(id)
		)
		
		# TODO: Possibly do something for the following three events.
		multiplayer.connected_to_server.connect(
			func():
				pass
				#connection_succeeded.emit()	
		)
		
		multiplayer.connection_failed.connect(
			func():
				pass
				multiplayer.multiplayer_peer = null
				#connection_failed.emit()
		)
		
		multiplayer.server_disconnected.connect(
			func():
				pass
				#game_error.emit("Server disconnected")
				#end_game()
		)
		
		# If lobby creation is successful, set the name of the lobby and create the 
		# multiplayer socket.
		Steam.lobby_created.connect(
			func(status: int, new_lobby_id: int):
				lobby_id = new_lobby_id
				if status == 1:
					Steam.setLobbyData(new_lobby_id, "name", 
						str(Steam.getPersonaName(), "'s MGA Lobby"))
					create_steam_socket()
				else:
					push_error("Error on create lobby!")
		)
		
		# When this client connects to a server. Includes when the client's own server.
		Steam.lobby_joined.connect(
			func(new_lobby_id: int, _permissions: int, _locked: bool, _response: int):
				lobby_id = new_lobby_id
				# If the client is not the server, tell the server that we are connected to it.
				var id = Steam.getLobbyOwner(new_lobby_id)
				if id != Steam.getSteamID():
					connect_steam_socket(id)
					register_player.rpc(player_name)
					players[multiplayer.get_unique_id()] = player_name
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Steam.run_callbacks()


# Set this client up as a game server through Steam.
func create_steam_socket():
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.set_multiplayer_peer(peer)


# Connect as a client to a Steam server.
func connect_steam_socket(steam_id : int):
	peer = SteamMultiplayerPeer.new()
	peer.create_client(steam_id, 0)
	multiplayer.set_multiplayer_peer(peer)


# Create a new public multiplayer lobby.
func host_lobby(host_player_name: String) -> void:
	if USING_GODOT_STEAM:
		player_name = host_player_name
		players[1] = host_player_name
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)


# Join an existing multiplayer lobby
func join_lobby(new_lobby_id : int, new_player_name : String):
	player_name = new_player_name
	Steam.joinLobby(new_lobby_id)


# Set up the shooting portion of the game. Switches the scene and loads the players.
func start_game():
	assert(multiplayer.is_server())
	load_game.rpc()
	
	var player_resource := load(player_scene)
	
	# Spawn each player at a spawn point.
	var spawn_point_index = 0
	for player_id in players.keys():
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


# Stops the connection between this player and the server if we are a client, or between
# all clients if we are the server.
func disconnect_local_player():
	if lobby_id != 0:
		# Close session with all users
		var local_player_steam_id: int = Steam.getSteamID()
		for player_index: int in range(Steam.getNumLobbyMembers(lobby_id)):
			# Make sure this isn't your Steam ID
			
			# NOTE: Steam.getNumLobbyMembers must be called before calling 
			# Steam.getLobbyMemberByIndex or else it doesn't return the correct result.
			var player_steam_id = Steam.getLobbyMemberByIndex(lobby_id, player_index)
			if player_steam_id != local_player_steam_id:
				# Close the P2P session
				Steam.closeP2PSessionWithUser(player_steam_id)
		
		# Leave the lobby and reset variables.
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		players.clear()


# Called when a new player enters the lobby
@rpc("any_peer", "call_local")
func register_player(new_player_name: String):
	var id = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()


# Remove a player from our map of registered players.
@rpc("any_peer", "call_local")
func unregister_player(id: int):
	players.erase(id)
	player_list_changed.emit()


# Load the main game scene and hide the menu.
@rpc("authority", "call_local", "reliable")
func load_game():
	var world = load(start_game_scene).instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("MainMenu").hide()

	get_tree().set_pause(false) 


# Add exp to this player.
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
		
		if multiplayer.is_server():
			players_selecting_upgrades = player_characters.size()
	
	for player in player_characters:
		player.emit_gained_experience(experience, level)


# Resumes game when all players have finished selecting upgrades. Only call on server. 
@rpc("any_peer", "call_local")
func player_selected_upgrade() -> void:
	if not multiplayer.is_server():
		return
	
	players_selecting_upgrades -= 1
	
	if players_selecting_upgrades <= 0:
		resume_game.rpc()


# Continues the game
@rpc("any_peer", "call_local")
func resume_game() -> void:
	get_tree().paused = false
