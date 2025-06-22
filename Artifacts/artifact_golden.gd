extends Artifact


var _owner: PlayerCharacterBody2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	get_tree().root.get_node("Playground").drop_weight_nothing = 0.0
	
	_owner = artifact_owner
	_owner.gained_experience.connect(_check_for_max_level)


## When the player reaches max level, make it so that only gold drops when enemies are defeated.
func _check_for_max_level(_exp, level) -> void:
	if level == GameState.MAX_LEVEL:
		get_tree().root.get_node("Playground").drop_weight_exp = 0.0
		_owner.gained_experience.disconnect(_check_for_max_level)
