extends Node

class_name MGAMultiplayerManager

# Port number for ENet multiplayer connections. Not commonly used or assigned:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const PORT_NUMBER: int = 34229

# Max number of players. I believe this includes the server.
const MAX_PLAYERS: int = 4

var peer: MultiplayerPeer = null

# Emitted after a peer is created
signal peer_created()
# Emitted after a host is created
signal host_created()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
# Create the server for the multiplayer game
func create_server():
	peer = ENetMultiplayerPeer.new()
	var create_server_result = peer.create_server(PORT_NUMBER, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	
	print(str(create_server_result))
	
	host_created.emit()
	print("Giga hosting!")

# Create a client for the multiplayer game
func create_client():
	peer = ENetMultiplayerPeer.new()
	# NOTE: For testing, I'll only be trying to connect to the localhost
	var create_client_result = peer.create_client("localhost", PORT_NUMBER)
	multiplayer.multiplayer_peer = peer
	
	print(create_client_result)
	
	peer_created.emit()
	print("Clienting!")

# Test function to see if server connection is working.
@rpc("any_peer", "call_local", "reliable")
func test_rpc():
	print("RPC has fired!")
