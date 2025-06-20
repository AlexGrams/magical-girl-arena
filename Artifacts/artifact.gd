class_name Artifact
extends Node
## Abstract class for an item that provides a passive bonus when acquired by the player.


@export_file("*.tres") var _artifactdata_path: String = ""

var artifactdata: ArtifactData = null


func _ready() -> void:
	artifactdata = load(_artifactdata_path)


func _process(_delta: float) -> void:
	pass


## Set up this artifact's passive 
func activate(_artifact_owner: PlayerCharacterBody2D) -> void:
	pass
