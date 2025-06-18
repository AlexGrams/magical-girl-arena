class_name StatusTempHealth
extends Node
## Health that goes away after a duration. When the owner takes damages, this value is decremented
## before their actual health is.


## How much longer this temp HP lasts before it goes away.
var duration: float = 0.0
## How much temp HP is remaining for this segment.
var value: int = 0

## Called when the duration of this segment finishes.
signal expired()


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		expired.emit()
		queue_free()
