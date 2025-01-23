extends Label

const DURATION:float = 1
var time_passed:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_passed = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	if time_passed >= DURATION:
		queue_free()
