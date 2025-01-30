extends Ability
# Unleash a powerful attack in a radius around you. 
# Any melee or ranged enemies killed by this attack become your allies for a brief duration. 
# When Goth’s Scythe is at max level, a large and powerful melee ally is also spawned at 
# your location.


@export var bullet_scene_path := "res://Abilities/bullet_ult_goth.tscn"
@export var damage: float = 100.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	# Spawn the large special damage volume at parent's location.
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
	1, [bullet_scene_path, 
		get_parent().global_position, 
		Vector2.ZERO, 
		damage, 
		[]
	]
)
