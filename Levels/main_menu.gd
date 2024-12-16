extends Node2D

@export var start_game_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_host_button_button_down() -> void:
	print("Hosting")
	#get_tree().change_scene_to_packed(start_game_scene)


func _on_quit_button_button_down() -> void:
	get_tree().quit()


func _on_lobby_button_button_down() -> void:
	$Main.visible = false
	$Lobby.visible = true


func _on_join_button_button_down() -> void:
	print("Joining (as peer)")
