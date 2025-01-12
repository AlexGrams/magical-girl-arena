extends Node

# Manager class for the overall state of the game scene. 
# Controls spawning players and related functionality. 

# Should only be false in debugging builds.
const USING_GODOT_STEAM := false
# Max number of players. I believe this includes the server.
const MAX_PLAYERS: int = 4
# The time in seconds that the host will wait for all clients to disconnect from it before
# closing its network connection when the host shuts down the lobby.
const HOST_CLOSE_RPC_TIMEOUT = 5.0
const start_game_scene := "res://Levels/playground.tscn"
const player_scene := "res://Player/player_character_body.tscn"
# Path from the root, not the path in the file system.
const main_menu_node_path := "MainMenu"
const lobby_list_path := "MainMenu/LobbyList"
const lobby_path := "MainMenu/Lobby"
const level_exp_needed: Array = [10, 10, 10, 10, 10, 10]

# The local player's name.
var player_name: String = ""
# TODO: Combine with "players" variables in some sort of map struct object.
# Map of player IDs to instantiated player characters in the game
var player_characters := {}
# Count of how many players are in the game. Can be different from len(players) because players
# can disconnect in the middle of a game.
var connected_players: int = 0
# Map of player IDs to their names.
var players := {}
# TODO: Can probably combine with "players" above.
# Map of Steam IDs to player IDs.
var steam_ids := {}
# This client's Steam ID
var local_player_steam_id: int = 0
# The multiplayer peer for the local player.
var peer: SteamMultiplayerPeer = null
# The Steam lobby ID of the lobby that this player is in.
var lobby_id: int = 0

# The parent node of all objects in the main portion of the game.
var world: Node = null
# Experience to next level
var experience: float = 0.0
# Current level
var level: int = 1
var players_selecting_upgrades: int = -1
# How many players are currently dead.
var players_down: int = 0

signal player_list_changed()
# Called when the host leaves the lobby.
signal lobby_closed()
# Emitted when all players are down
signal game_over()

# Emitted after the last client disconnects from the host, or enough time passes.
signal _no_clients_connected_or_timeout()


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
		
		local_player_steam_id = Steam.getSteamID()
		
		multiplayer.peer_connected.connect(
			func(id : int):
				# Tell the connected peer that this client is in the lobby.
				register_player.rpc_id(id, player_name, local_player_steam_id)
		)
		
		# TODO: See if we can use this or get it to work, don't know.
		multiplayer.peer_disconnected.connect(
			func(_id : int):
				if len(multiplayer.get_peers()) == 0:
					_no_clients_connected_or_timeout.emit()
		)
		
		# TODO: Possibly do something for the following three events.
		multiplayer.connected_to_server.connect(
			func():
				# Tell all clients (including the local one) this client's information.
				register_player.rpc(player_name, local_player_steam_id)
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
				# If the client is not the server, create a Steam socket connection.
				var id = Steam.getLobbyOwner(new_lobby_id)
				if id != local_player_steam_id:
					connect_steam_socket(id)
		)
		
		Steam.lobby_chat_update.connect(
			func(_updated_lobby_id: int, changed_id: int, _making_change_id: int, chat_state: int):
				# chat_state is a bitfield indicating what the Steam user changed_id has done
				# More: https://partner.steamgames.com/doc/api/ISteamMatchmaking#LobbyChatUpdate_t 
				if chat_state & 2:
					# Player left a lobby
					unregister_player_by_steam_id(changed_id)
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
		steam_ids[local_player_steam_id] = 1
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
		var player: PlayerCharacterBody2D = player_resource.instantiate()
		player.set_label_name(str(player_id))
		get_tree().root.get_node("Playground").add_child(player, true)
		
		player.died.connect(func():
			_on_player_died.rpc()
		)
		player.revived.connect(func():
			_on_player_revived.rpc()
		)
		
		# Get the player's view to only follow this character
		player.set_camera_current.rpc_id(player_id)
		
		player.register_with_game_state.rpc(player_id)
		
		# Players need to be given authority over their characters, and other players
		# need to have authority set locally for each remote player.
		player.set_authority.rpc(player_id)
		player.ready_local_player.rpc_id(player_id)
		
		var spawn_point: Vector2 = get_tree().root.get_node("Playground/PlayerSpawnPoints").get_child(spawn_point_index).position
		player.teleport.rpc_id(player_id, spawn_point)
		spawn_point_index += 1


# Stops the main gameplay segment by deleting the world and resetting state variables.
@rpc("any_peer", "call_local")
func end_game():
	reset_game_variables()
	
	if multiplayer.is_server():
		# TODO: Maybe only call this whole function on the server?
		if world != null:
			world.queue_free()
	world = null


# Only affects variables related to gameplay. Multiplayer properties are not changed.
func reset_game_variables():
	player_characters.clear()
	players_down = 0
	level = 1
	experience = 0


# Add a player character to local list of spawned characters
func add_player_character(player_id: int, player_character: CharacterBody2D) -> void:
	if player_character == null:
		return
	
	player_characters[player_id] = player_character
	
	# Update our count of player character nodes when they are added and removed from the scene.
	connected_players += 1
	player_character.tree_exiting.connect(func():
		connected_players -= 1
	)


# Closes notifies this client that the lobby closed and disconnects the client.
# Should only be called by the lobby host.
@rpc("any_peer", "call_remote")
func lobby_host_left():
	disconnect_local_player()
	lobby_closed.emit()


# Stops the connection between this player and the server if we are a client, or between
# all clients if we are the server.
func disconnect_local_player():
	if lobby_id != 0:
		# Close session with all users
		for player_index: int in range(Steam.getNumLobbyMembers(lobby_id)):
			# Make sure this isn't your Steam ID
			
			# NOTE: Steam.getNumLobbyMembers must be called before calling 
			# Steam.getLobbyMemberByIndex or else it doesn't return the correct result.
			var player_steam_id = Steam.getLobbyMemberByIndex(lobby_id, player_index)
			if player_steam_id != local_player_steam_id:
				# Close the P2P session
				Steam.closeP2PSessionWithUser(player_steam_id)
		
		# If this client was the host, also disconnect the other players if they exist.
		if (multiplayer.has_multiplayer_peer() 
			and multiplayer.get_unique_id() == 1
			and len(players) > 1
		):
			for player: int in players:
				if player != 1:
					lobby_host_left.rpc_id(player)
			
			# Sort of a hack. We need to ensure that the RPCs are sent to the other clients
			# before closing the connection. To do so, until all the other clients have left.
			var timeout_func = func():
				await get_tree().create_timer(HOST_CLOSE_RPC_TIMEOUT).timeout
				_no_clients_connected_or_timeout.emit()
			timeout_func.call()
			
			await _no_clients_connected_or_timeout
		
		# Leave the lobby and reset variables.
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		players.clear()
		peer.close()
		peer = null


# Called when a new player enters the lobby
@rpc("any_peer", "call_local")
func register_player(new_player_name: String, new_steam_id: int):
	var id = multiplayer.get_remote_sender_id()
	
	players[id] = new_player_name
	steam_ids[new_steam_id] = id
	player_list_changed.emit()


# Remove a player from our map of registered players.
@rpc("any_peer", "call_local")
func unregister_player(id: int):
	players.erase(id)
	# Hack to remove from steam_ids as well
	for steam_id in steam_ids:
		if steam_ids[steam_id] == id:
			steam_ids.erase(steam_id)
			break
	
	player_list_changed.emit()


# Remove a player's variables using their unique Steam ID.
func unregister_player_by_steam_id(steam_id: int):
	players.erase(steam_ids[steam_id])
	steam_ids.erase(steam_id)
	player_list_changed.emit()


# Disconnect the local player and return everyone else to the lobby screen.
# Called by the player that presses the "Quit" button on the game over screen.
@rpc("any_peer", "call_local", "reliable")
func quit_game(quitting_player: int):
	var main_menu: MainMenu = get_tree().get_root().get_node(main_menu_node_path)
	var lobby: Control = get_tree().get_root().get_node(lobby_path)
	
	end_game()
	main_menu.show()
	if multiplayer.get_unique_id() == quitting_player:
		# We wait for one frame before disconnecting the client to ensure the RPC to 
		# quit_game is sent to all clients. Otherwise, quit_game is not called on 
		# other players as the sender (this client) is disconnected before the RPC goes out.
		await get_tree().process_frame
		await get_tree().process_frame
		
		var lobby_list: Control = get_tree().get_root().get_node(lobby_list_path)
		disconnect_local_player()
		lobby.hide()
		lobby_list.show()
	else:
		# TODO: Maybe something different needs to happen if the host presses "Quit"
		main_menu.refresh_lobby()


# Load the main game scene and hide the menu.
@rpc("authority", "call_local", "reliable")
func load_game():
	if not multiplayer.is_server():
		return
	
	world = load(start_game_scene).instantiate()
	get_tree().get_root().add_child(world, true)
	get_tree().get_root().get_node(main_menu_node_path).hide()

	get_tree().set_pause(false) 


# Add exp to this player.
@rpc("any_peer", "call_local")
func collect_exp() -> void:
	experience += 5
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
	
	for player in player_characters.values():
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


# Keep track of how many players are still alive, and end the game if there are none.
@rpc("any_peer", "call_local")
func _on_player_died():
	players_down += 1
	if players_down >= connected_players:
		game_over.emit()


@rpc("any_peer", "call_local")
func _on_player_revived():
	players_down -= 1
