class_name LootBox
extends DestructibleNode2D
## A neutral destructable object in the world. When the player breaks it, 
## has a chance of spawning items such as gold or health for the player.
## Enemies cannot interact with a LootBox.

## Relative likelihood of dropping a health pickup when destroyed.
@export var drop_weight_health: float = 1.00
## Relative likelihood of dropping gold when destroyed.
@export var drop_weight_gold: float = 1.0
## Health pickup scene.
@export var health_scene: Resource = null
## Gold pickup scene.
@export var gold_scene: Resource = null
## Leaf explosion scene.
@export var leaf_explosion_scene: Resource = null

var _threshold_health: float = 1.0
var _threshold_gold: float = 1.0
var _tree: SceneTree = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	# Random loot generation
	var total := drop_weight_health + drop_weight_gold
	_threshold_health = drop_weight_health / total
	_threshold_gold = drop_weight_gold / total + _threshold_health
	
	# Show leaves exploding effect when destroyed
	_tree = get_tree()
	tree_exited.connect(func():
		var playground: Node2D = _tree.root.get_node_or_null("Playground")
		if playground:
			var leaf_explosion: GPUParticles2D = leaf_explosion_scene.instantiate()
			leaf_explosion.global_position = global_position
			playground.add_child(leaf_explosion)
	)


func _on_area_2d_entered(area: Area2D) -> void:
	super(area)


## Break this object and create a pickup. Only call on server.
func _destroy() -> void:
	# Spawn random loot
	var random_value := randf()
	if random_value <= _threshold_health:
		var health_pickup: HealthOrb = health_scene.instantiate()
		health_pickup.global_position = global_position
		health_pickup.tree_entered.connect(
			func(): health_pickup.teleport.rpc(global_position)
			, CONNECT_DEFERRED
		)
		get_tree().root.get_node("Playground").call_deferred("add_child", health_pickup, true)
	elif random_value <= _threshold_gold:
		var gold: Node2D = gold_scene.instantiate()
		gold.global_position = global_position
		gold.tree_entered.connect(
			func(): gold.teleport.rpc(global_position)
			, CONNECT_DEFERRED
		)
		get_tree().root.get_node("Playground").call_deferred("add_child", gold, true)
	
	super()
