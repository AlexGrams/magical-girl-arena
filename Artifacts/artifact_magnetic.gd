extends Artifact
## Collect all EXP and Gold on the field every minute.


@export var _collect_interval: float = 60.0

@onready var _current_collect_time: float = _collect_interval
var _owner: PlayerCharacterBody2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_current_collect_time -= delta
	
	if _current_collect_time <= 0.0:
		_current_collect_time = _collect_interval
		_owner.collect_all_pickups.rpc()


## Disable owner's collection radius.
func activate(artifact_owner: PlayerCharacterBody2D) -> void:
	artifact_owner.set_exp_pickup_enabled.rpc(false)
	_owner = artifact_owner
