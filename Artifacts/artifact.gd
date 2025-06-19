class_name Artifact
extends Node
## Abstract class for an item that provides a passive bonus when acquired by the player.


func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	pass


## Set up this artifact's passive 
func activate(_artifact_owner: PlayerCharacterBody2D) -> void:
	pass
