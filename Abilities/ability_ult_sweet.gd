extends Ability
# Sweet grants herself and nearby allies bonus HP. She throws tarot cards
# in 12 directions, which deal damage and pierce through enemies. 
# Sweet gains +1 reroll.

const _NUM_BULLETS := 12

@export var bullet_scene_path := "res://Abilities/bullet_ult_goth.tscn"


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
		true,
		[]
	]
)
