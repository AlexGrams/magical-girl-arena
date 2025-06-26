class_name BigEXPOrb
extends EXPOrb

## How much experience is gained when collecting this big exp orb.
@export var _exp_amount: int = 1000


## Destroys orb and adds lot of EXP. Called when EXP orb touches a player.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	var hit_node: Node = area.get_parent()
	if uncollected and hit_node != null and hit_node.is_in_group("player"):
		uncollected = false
		GameState.collect_exp.rpc(_exp_amount, global_position)
		destroy()
