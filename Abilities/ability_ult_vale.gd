extends Ability
## Fire a bunch of missiles all around the player. Missiles are distributed among "slices"
## around the player so as to not all randomly fire at the same location.

## How many bullets are created by this ability.
@export var _num_missiles: int = 24
## How much damage each missile does when it touches an enemy. Missiles do not explode after touching.
@export var _touch_damage: float = 100.0
## How much damage each missile does after exploding. Damage is dealt in an area.
@export var _explosion_damage: float = 100.0
## Minimum distance from the player that the missiles will target.
@export var _min_range: float = 500.0
## Maximum distance from the player that the missiles will target.
@export var _max_range: float = 1250.0
## Higher values will make missiles more evenly spread around the player, while lower values can make the
## spread more lopsided. Each missile is assigned a "slice" of the circle around the player for it to target.
@export var _num_slices: int = 6
@export var _bullet_scene_uid := ""


var _temp_health_ranged_squared: float = 0.0
## Number of radians that each slice consists of.
var _rad_per_slice: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	_rad_per_slice = deg_to_rad(360.0 / _num_slices)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	AudioManager.create_audio_at_location.rpc(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_SWEET_ULTIMATE)
	
	# Shoot missiles all around in a sort of random way.
	var slice_rotator = Vector2.UP
	
	for i in range(_num_missiles):
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [_bullet_scene_uid, 
				get_parent().global_position, 
				slice_rotator.rotated(randf_range(0.0, _rad_per_slice)), 
				_touch_damage, 
				true,
				[_touch_damage, _explosion_damage, randi_range(0, BulletUltVale.MOVEMENT_PATTERNS - 1)]
		])
		
		slice_rotator = slice_rotator.rotated(_rad_per_slice)
