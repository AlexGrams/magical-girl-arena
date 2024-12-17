extends Node2D

@export var start_game_scene: PackedScene

var timer = -1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass

func _on_quit_button_button_down() -> void:
	get_tree().quit()


func _on_lobby_button_button_down() -> void:
	$Main.visible = false
	$Lobby.visible = true


func _on_host_button_button_down() -> void:
	MultiplayerManager.create_server()
	#get_tree().change_scene_to_packed(start_game_scene)
	
	multiplayer.multiplayer_peer.peer_connected.connect(on_peer_connected)


func _on_join_button_button_down() -> void:
	MultiplayerManager.create_client()

func on_peer_connected(id: int) -> void:
	say_something.rpc()

# Test function to see if server connection is working.
@rpc("any_peer", "call_local", "reliable")
func say_something():
	print("A peer was connected")
