class_name Status
extends Node
## Base class for status effects. Applies an effect to parent node for some time, then reverts that
## effect when the effect duration runs out.


## How much longer this status lasts before it goes away.
var duration: float = 0.0

## Called when the duration of this segment finishes.
signal expired()


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		expired.emit()
		queue_free()
