extends Powerup

## Time in seconds between creating bullets.
@export var shoot_interval = 1.0
## Path to the Bullet-derived bullet scene.
@export var bullet_scene := ""

# TODO: Do we even need this? If so, it should probably go in Powerup and not here.
#@export var sprite: Resource = null
var bullet
var is_on := false
var shoot_timer: float = 0.0


func _ready() -> void:
	powerup_name = "Scythe"


func _process(delta: float) -> void:
	if not is_on:
		return
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		if _is_owned_by_player:
			var direction = (get_global_mouse_position() - self.global_position).normalized()
			get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
				1,
				[
					bullet_scene, 
					Vector2.ZERO, 
					direction, 
					upgrade_curve.sample(float(current_level) / max_level), 
					_is_owned_by_player,
					[multiplayer.get_unique_id()]
				]
			)
		else:
			var owning_enemy: Node2D = get_parent()
			
			if owning_enemy != null:
				var direction = owning_enemy.target.global_position - self.global_position
				direction = direction.normalized()
				
				get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
					1, 
					[
						bullet_scene, 
						Vector2.ZERO, 
						direction, 
						owning_enemy.attack_damage, 
						_is_owned_by_player,
						[owning_enemy.get_path()]
					]
				)
		
		shoot_timer = 0


func activate_powerup():
	is_on = true


func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false
	shoot_timer = 0.0


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, upgrade_curve.sample(float(current_level) / max_level))
