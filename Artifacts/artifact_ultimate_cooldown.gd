extends Artifact
## Halves ultimate cooldown time


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Halves ultimate cooldown time.
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner.scale_ultimate_cooldown(0.5)
