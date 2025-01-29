extends Ability
# Unleash a powerful attack in a radius around you. 
# Any melee or ranged enemies killed by this attack become your allies for a brief duration. 
# When Goth’s Scythe is at max level, a large and powerful melee ally is also spawned at 
# your location.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	print("bababooey")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
