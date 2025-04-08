class_name SignaturePowerupOrb
extends EXPOrb


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## Destroys this object and gives a Powerup upgrade if possible.
func _on_area_2d_area_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if (uncollected 
		and multiplayer.get_unique_id() == area.get_multiplayer_authority() 
		and other is PlayerCharacterBody2D
	):
		# Check if player can pick up this upgrade
		uncollected = false
		destroy.rpc_id(1) 


## Does nothing to prevent this orb type from gravitating. Should not be called.
@rpc("any_peer", "call_local")
func set_player(_new_player: NodePath) -> void:
	pass
