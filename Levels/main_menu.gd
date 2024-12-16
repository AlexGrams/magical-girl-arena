extends Node2D

@export var start_game_scene: PackedScene

var timer = -1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	if timer >= 0.0:
		timer += delta
		if timer >= 1.0:
			MultiplayerManager.test_rpc.rpc()
			timer = -1.0

func _on_quit_button_button_down() -> void:
	get_tree().quit()


func _on_lobby_button_button_down() -> void:
	$Main.visible = false
	$Lobby.visible = true


func _on_host_button_button_down() -> void:
	MultiplayerManager.create_server()
	#get_tree().change_scene_to_packed(start_game_scene)


func _on_join_button_button_down() -> void:
	MultiplayerManager.create_client()
	timer = 0.0
