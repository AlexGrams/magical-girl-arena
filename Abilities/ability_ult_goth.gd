extends Ability
# Unleash a powerful attack in a radius around you. 
# Any melee or ranged enemies killed by this attack become your allies for a brief duration. 
# When Goth’s Scythe is at max level, a large and powerful melee ally is also spawned at 
# your location.


@export var _damage_curve: Curve = preload("res://Curves/Abilities/ability_ult_goth.tres")

@export var bullet_scene_path := "res://Abilities/bullet_ult_goth.tscn"
@export var status_duration: float = 1.0

var _damage: float = 100.0


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
		_damage * (1.0 if randf() > _crit_chance else 2.0), 
		false,
		true,
		-1,
		-1,
		[status_duration]
	])


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	_damage = _damage_curve.sample(float(_level) / GameState.MAX_LEVEL)
