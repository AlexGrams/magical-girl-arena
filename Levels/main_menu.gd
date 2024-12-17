extends Node2D

var timer = -1.0
# Map of connected players to their data
var player_ids = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _process(_delta: float) -> void:
	pass


func _on_quit_button_button_down() -> void:
	get_tree().quit()


func _on_lobby_button_button_down() -> void:
	$Main.visible = false
	$Lobby.visible = true


func _on_host_button_button_down() -> void:
	MultiplayerManager.create_server()


func _on_join_button_button_down() -> void:
	MultiplayerManager.create_client()


# Called when this player is hosting and a client connects to it.
func _on_peer_connected(id: int) -> void:
	player_ids[id] = null
	
	if multiplayer.get_unique_id() == 1:
		GameState.start_game()


# Called when this player is hosting and a client disconnects from it.
func _on_peer_disconnected(id: int) -> void:
	player_ids.erase(id)
