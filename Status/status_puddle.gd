class_name StatusPuddle
extends Status
## Status effect applied by the Puddle powerup to allies that touch puddle bullets. Increases speed
## and health regen slightly. Effect does not stack, but the duration is refreshed while a player
## is touching a puddle.


func _ready() -> void:
	super()


func _process(delta: float) -> void:
	super(delta)
