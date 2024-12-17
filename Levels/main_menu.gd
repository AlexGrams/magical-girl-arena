extends Node2D

@export var start_game_scene: PackedScene

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
	start_game.rpc()


# Called when this player is hosting and a client disconnects from it.
func _on_peer_disconnected(id: int) -> void:
	player_ids.erase(id)


# Load the main game scene.
@rpc("authority", "call_local", "reliable")
func start_game():
	get_tree().change_scene_to_packed(start_game_scene)
