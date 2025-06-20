extends Ability
# Sweet grants herself and nearby allies bonus HP. She throws tarot cards
# in 12 directions, which deal damage and pierce through enemies. 
# Sweet gains +1 reroll.

const _NUM_BULLETS := 12

@export var _damage_curve: Curve = preload("res://Curves/Abilities/ability_ult_sweet.tres")

@export var bullet_scene_path := "res://Abilities/bullet_ult_sweet.tscn"
## How much temporary health is granted to nearby players when this Ability is used.
@export var temp_health_healing: int = 50
## Radius in which nearby players are granted temporary health by this Ability.
@export var temp_health_range: float = 1000.0

var _damage: float = 100.0
var _temp_health_ranged_squared: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	_temp_health_ranged_squared = temp_health_range ** 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	AudioManager.create_audio_at_location.rpc(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_SWEET_ULTIMATE)
	# Shoot bullets all around
	var rotation_increment: float = 2 * PI / _NUM_BULLETS
	for i in range(_NUM_BULLETS):
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [bullet_scene_path, 
			get_parent().global_position, 
			Vector2.UP.rotated(rotation_increment * i), 
			_damage, 
			true,
			-1,
			-1,
			[]
	])
	
	# Give a temp reroll
	get_parent().increment_temp_rerolls()
	
	# Give temp health in an area
	var owner_position: Vector2 = get_parent().global_position
	for player: PlayerCharacterBody2D in get_tree().get_nodes_in_group("player"):
		if owner_position.distance_squared_to(player.global_position) <= _temp_health_ranged_squared:
			player.add_temp_health.rpc(temp_health_healing)


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	_damage = _damage_curve.sample(float(_level) / GameState.MAX_LEVEL)
