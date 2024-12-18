extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


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
