class_name Artifact
extends Node
## Abstract class for an item that provides a passive bonus when acquired by the player.


## True if the player can have more than one of this charm at a time.
@export var allow_duplicates: bool = false

var artifactdata: ArtifactData = null


func set_artifactdata(new_artifactdata: ArtifactData) -> void:
	artifactdata = new_artifactdata


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


## Set up this artifact's passive 
func activate(_artifact_owner: PlayerCharacterBody2D) -> void:
	pass
