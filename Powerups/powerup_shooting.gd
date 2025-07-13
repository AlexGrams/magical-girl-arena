extends Powerup

@export var shoot_interval: float = 1.0
@export var bullet_damage: float = 50.0
@export var bullet_scene := "res://Powerups/bullet.tscn"

@onready var shoot_timer: float = shoot_interval
var crit:bool = false

signal picked_up_powerup(sprite)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bullet_damage = _get_damage_from_curve()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		var direction := Vector2.ZERO
		if _is_owned_by_player:
			# Player bullet moves in direction of cursor.
			direction = (get_global_mouse_position() - self.global_position).normalized()
		else:
			# Enemy bullet moves in direction of Enemy's desired velocity.
			direction = get_parent().velocity.normalized()
		var bullet_position := self.global_position + (direction * 100)
		
		crit = randf() >= 0.75
		
		var actual_bullet_damage = bullet_damage * 2 if crit else bullet_damage
		AudioManager.create_audio_at_location(bullet_position, SoundEffectSettings.SOUND_EFFECT_TYPE.SHOOTING)
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [bullet_scene, 
				bullet_position, 
				direction, 
				actual_bullet_damage, 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[]
			]
		)
		if current_level >= 3:
			## Shoot 4 bullets in random directions. They cannot crit.
			actual_bullet_damage = bullet_damage
			for i in range(4):
				direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				bullet_position = self.global_position + (direction * 100)
				get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1, [bullet_scene, 
					bullet_position, 
					direction, 
					actual_bullet_damage, 
					_is_owned_by_player,
					multiplayer.get_unique_id(),
					_powerup_index,
					[]
					]
				)
		
		shoot_timer = 0


func activate_powerup():
	is_on = true
	picked_up_powerup.emit()


func deactivate_powerup():
	is_on = false
	shoot_timer = 0.0


func level_up():
	current_level += 1
	bullet_damage = _get_damage_from_curve()
	powerup_level_up.emit(current_level, bullet_damage)
