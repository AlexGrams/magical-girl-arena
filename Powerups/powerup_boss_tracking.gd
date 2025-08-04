extends Powerup
## A boss powerup that always shoots at the nearest player. Similar to powerup_shooting


@export var _shoot_interval: float = 1.0
@export var _bullet_damage: float = 20.0
@export var _bullet_uid := ""

var _shoot_timer: float = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on:
		return
	
	_shoot_timer += delta
	if _shoot_timer > _shoot_interval:
		var direction := Vector2.ZERO
		if _is_owned_by_player:
			# Not implemented for use with Players.
			push_warning("Not implemented!")
		else:
			# Bullet goes towards nearest Player character.
			var closest_position := Vector2.ZERO
			var closest_distance: float = INF
			for player: PlayerCharacterBody2D in GameState.player_characters.values():
				if not player.is_down and player.global_position.distance_squared_to(global_position) < closest_distance:
					closest_position = player.global_position
			direction = (closest_position - global_position).normalized()
		
		var bullet_position := self.global_position + (direction * 100)
		
		get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
			1, [_bullet_uid, 
				bullet_position, 
				direction, 
				_bullet_damage, 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				_powerup_index,
				[]
			]
		)
		
		_shoot_timer = 0


func activate_powerup():
	is_on = true
	_is_owned_by_player = false
	_shoot_timer = 0.0


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1
