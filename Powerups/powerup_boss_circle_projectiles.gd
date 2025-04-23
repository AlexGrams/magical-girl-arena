extends Powerup
# Shoots a bunch of projectiles out in a circle

const _NUM_BULLETS := 12

@export var bullet_scene_uid := "res://Abilities/bullet_ult_sweet.tscn"
@export var damage: float = 25.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func activate_powerup():
	# TODO: Start shooting
	pass


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	# TODO: Stop shooting
	pass


# Shoot around in a circle.
func shoot() -> void:
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_SWEET_ULTIMATE)
	# Shoot bullets all around
	var rotation_increment: float = 2 * PI / _NUM_BULLETS
	for i in range(_NUM_BULLETS):
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [bullet_scene_uid, 
			get_parent().global_position, 
			Vector2.UP.rotated(rotation_increment * i), 
			damage, 
			true,
			[]
		])
