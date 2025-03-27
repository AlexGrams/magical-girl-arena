class_name LootBoxSpawner
extends AreaSpawner


## Time in seconds between spawning LootBoxes
@export var spawn_interval: float = 1.0
@export var loot_box_scene: PackedScene = null

var _time: float = 0.0


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	_time += delta
	if _time >= spawn_interval:
		var loot_box: LootBox = spawn(loot_box_scene)
		loot_box.set_position_for_clients.rpc(loot_box.global_position)
		_time = 0.0
