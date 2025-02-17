extends Node

class_name MGAMultiplayerManager

# Port number for ENet multiplayer connections. Not commonly used or assigned:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const PORT_NUMBER: int = 34229

var peer: MultiplayerPeer = null
# Map of connected players to their data
var player_ids = {}

# Emitted after a peer is created
signal peer_created()
# Emitted after a host is created
signal host_created()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Creates an ENet multiplayer lobby with this player as the server. If the server already exists,
# then join it as a client instead. Used for testing.
func join_multiplayer_lobby_using_enet():
	peer = ENetMultiplayerPeer.new()
	var create_server_result = peer.create_server(PORT_NUMBER, GameState.MAX_PLAYERS)
	
	if create_server_result == OK:
		# Server created
		multiplayer.multiplayer_peer = peer

		player_ids[1] = null
		GameState.register_player(multiplayer.get_unique_id(), "Host", GameState.local_player_steam_id)
		
		host_created.emit()
	else:
		# Client created, or some unrelated error happened. Won't consider that case.
		push_warning("Ignore previous error.")
		
		var create_client_result = peer.create_client("localhost", PORT_NUMBER)
		multiplayer.multiplayer_peer = peer

		if create_client_result != OK:
			print("Error when creating client: " + str(create_client_result))
			return

		peer_created.emit()


# Called on all players when a client connects.
# id = unique id of the client that connected
func _on_peer_connected(id: int) -> void:
	GameState.register_player(id, "Client", GameState.local_player_steam_id)
	player_ids[id] = null


# Called on all players when a client disconnects.
func _on_peer_disconnected(id: int) -> void:
	player_ids.erase(id)
