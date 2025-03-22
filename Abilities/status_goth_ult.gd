class_name StatusGothUlt
extends Node2D
## Status affecting enemies hit by Goth's ultimate. If the Enemy dies while this status is
## active, then they are converted to an ally temporarily before despawning.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Async function to destroy this marker after the status lifetime has elapsed
func destroy_after_duration(duration: float) -> void:
	$"..".allied.connect(func(_enemy: Enemy):
		queue_free()
	)
	
	await get_tree().create_timer(duration).timeout
	
	queue_free()
