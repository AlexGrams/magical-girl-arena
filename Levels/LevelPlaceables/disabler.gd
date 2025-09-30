class_name Disabler
extends Node2D
## A Node that disables all powerups except those of a certain type when a player is nearby.





func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass


func _on_disable_area_2d_area_entered(area: Area2D) -> void:
	print(area.get_parent().name)


func _on_disable_area_2d_area_exited(area: Area2D) -> void:
	print(area.get_parent().name)
