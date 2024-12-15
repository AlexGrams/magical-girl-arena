extends Node2D

@export var start_game_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_start_button_button_down() -> void:
	get_tree().change_scene_to_packed(start_game_scene)


func _on_quit_button_button_down() -> void:
	get_tree().quit()
