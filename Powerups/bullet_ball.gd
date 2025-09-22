class_name BulletBall
extends Bullet


## Ball is not considered to be moving if its squared speed is less than this value.
const MOVING_THRESHOLD_SQUARED: float = 4.0

@export var _explosion_damage: float = 50.0
## Impulse applied to the ball when it touches a player.
@export var _kick_impulse: float = 10000.0
## Torque impule applied to the ball when it is kicked.
@export var _kick_torque: float = 900.0
## How much the bigger the ball gets with each kill.
@export var _size_increment: float = 1.0
@export var _max_size: float = 10.0
## Time in seconds after which the ball teleports to its owning player if it hasn't been hit.
@export var _max_recall_time: float = 20.0
@export var _explosion_vfx_scene_path: String = ""
@export var _rigidbody: RigidBody2D = null
@export var _sprite_holder: Node2D = null
@export var _kick_area: Area2D = null
@export var _explosion_bullet_hitbox: BulletHitbox = null
@export var _physics_collision_shape: CollisionShape2D

var _size_increment_vector: Vector2 = Vector2.ONE
## The original collision layer of the BulletHitbox for explosion damage.
var _explosion_hitbox_collision_layer: int = 0
## Number of Enemies that the Ball has killed, meaning it did the final amount of damage to them.
## Each kill increases the Ball's damage.
var _kills: int = 0
## How much extra growth has been added to the Ball so far.
var _total_growth: float = 0.0
var _recall_timer: float = 0.0
## True when the explosion hitbox has collision enabled and can deal damage.
var _explosion_active: bool = false
var _explosion_scene: PackedScene = null
var _owning_player: PlayerCharacterBody2D = null
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
## The PowerupBall of the owning player if it exists on this client.
var _ball_powerup: PowerupBall = null


func set_damage(damage: float, _is_crit: bool = false):
	collider.damage = damage


@rpc("any_peer", "call_local")
func _set_critical(new_crit_chance: float, new_crit_multiplier: float):
	_crit_chance = new_crit_chance
	_crit_multiplier = new_crit_multiplier


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
	_explosion_hitbox_collision_layer = _explosion_bullet_hitbox.collision_layer
	_explosion_bullet_hitbox.collision_layer = 0
	ResourceLoader.load_threaded_request(_explosion_vfx_scene_path, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)


func _process(delta: float) -> void:
	# Teleport back to owner if we haven't been hit in a while.
	_recall_timer += delta
	if _recall_timer > _max_recall_time:
		global_position = _owning_player.global_position


func _physics_process(_delta: float) -> void:
	if _explosion_active:
		if _explosion_bullet_hitbox.collision_layer != _explosion_hitbox_collision_layer:
			_explosion_bullet_hitbox.collision_layer = _explosion_hitbox_collision_layer
		else:
			_explosion_bullet_hitbox.collision_layer = 0
			_explosion_active = false


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 3
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning player
		or typeof(data[1]) != TYPE_INT			# Kills Ball has gotten so far
		or typeof(data[2]) != TYPE_FLOAT		# Growth so far
	):
		push_error("Malformed data array")
		return
	
	_size_increment_vector = Vector2.ONE * _size_increment
	_owning_player = get_node(data[0])
	_kills = data[1]
	if data[2] > 0:
		_set_growth(data[2])
	_is_owned_by_player = is_owned_by_player
	
	_explosion_bullet_hitbox.damage = _explosion_damage
	
	# Make a pointer for the Ball when it goes offscreen
	GameState.playground.hud_canvas_layer.add_node_to_point_to(self, sprite.texture)
	
	if _owning_player != null and is_multiplayer_authority():
		_owning_player.died.connect(func():
			queue_free()
		)
	
	# The Powerup child is not replicated, so only the client which owns this character has it.
	_ball_powerup = _owning_player.get_node_or_null("PowerupBall")
	if _ball_powerup != null:
		# Apply level 3 upgrade upon respawning the Ball.
		if _ball_powerup.current_level >= 3:
			_size_increment *= 1.5
			_size_increment_vector *= 1.5
		
		_ball_powerup.powerup_level_up.connect(
			func(new_level, new_damage):
				_level_up.rpc(new_level, new_damage)
		)
		
		# Update crit values
		_ball_powerup.crit_changed.connect(
			func(new_crit_chance: float, new_crit_multiplier: float):
				_set_critical.rpc_id(1, new_crit_chance, new_crit_multiplier)
		)
		
		_ball_powerup.set_ball(self)


## This bullet's owner has leveled up its corresponding powerup.
@rpc("any_peer", "call_local")
func _level_up(new_level: int, new_damage: float):
	collider.damage = new_damage + _kills
	
	# Level 3: Increase growth rate.
	if new_level == 3:
		_size_increment *= 1.5
		_size_increment_vector *= 1.5


## Increases the ball's current size and its max size. 
@rpc("any_peer", "call_local")
func boost_area_size() -> void:
	_max_size += _size_increment * 10
	_grow(10)


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass


func _on_player_kick_area_2d_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if other is PlayerCharacterBody2D:
		# Kick the ball by applying force and torque. Torque is only for visuals.
		var kick_direction: Vector2 = (global_position - other.global_position).normalized()
		_rigidbody.apply_force(kick_direction * _kick_impulse)
		
		if kick_direction.x > 0:
			_rigidbody.apply_torque_impulse(_kick_torque)
		else:
			_rigidbody.apply_torque_impulse(-_kick_torque)
		
		_recall_timer = 0.0


## Damage hit Enemies. Only called on server.
func _on_bullet_hitbox_entered(area: Area2D) -> void:
	# Can only deal damage while moving.
	if _rigidbody.linear_velocity.length_squared() < MOVING_THRESHOLD_SQUARED:
		return
	
	var other: Node2D = area.get_parent()
	if other is Enemy:
		if is_multiplayer_authority():
			if other.health - collider.damage <= 0:
				# The Ball probably just got a kill, so increase its size.
				_kills += 1
				collider.damage += 1.0
				if _total_growth < _max_size:
					_grow.rpc()
				else:
					pass
					# TODO: Disabling Ball explosion.
					#_explode.rpc()
				_record_ball_stats.rpc_id(collider.owner_id, _kills, _total_growth)
			
			if randf() < _crit_chance:
				collider.is_crit = true
				other.take_damage(collider.damage * _crit_multiplier, collider)
			else:
				collider.is_crit = false
				other.take_damage(collider.damage, collider)
		
		if collider.owner_id == multiplayer.get_unique_id():
			Analytics.add_powerup_damage(collider.damage, collider.powerup_index)


## Make the ball bigger.
@rpc("authority", "call_local")
func _grow(times: int = 1) -> void:
	_total_growth += _size_increment * times
	_sprite_holder.scale += _size_increment_vector * times
	collider.scale += _size_increment_vector * times
	_kick_area.scale += _size_increment_vector * times
	_physics_collision_shape.scale += _size_increment_vector * times


@rpc("authority", "call_local")
func _set_growth(total_growth: float) -> void:
	total_growth += 1.0
	_total_growth = total_growth
	_sprite_holder.scale = Vector2.ONE * total_growth
	collider.scale = Vector2.ONE * total_growth
	_kick_area.scale = Vector2.ONE * total_growth
	_physics_collision_shape.scale = Vector2.ONE * total_growth


## Return the ball to its original size and instantiate explosion particle effects.
@rpc("authority", "call_local")
func _explode() -> void:
	_explosion_active = true
	
	# VFX
	if _explosion_scene == null:
		_explosion_scene = ResourceLoader.load_threaded_get(_explosion_vfx_scene_path)
	var explosion_vfx = _explosion_scene.instantiate()
	explosion_vfx.global_position = global_position
	GameState.playground.add_child(explosion_vfx)
	
	_sprite_holder.scale = Vector2.ONE
	collider.scale = Vector2.ONE
	_kick_area.scale = Vector2.ONE
	_physics_collision_shape.scale = Vector2.ONE
	_kills = 0


## Tell the Ball owner's PowerupBall that this Ball just got a kill. Only call on Ball owner.
@rpc("authority", "call_local")
func _record_ball_stats(kills: int, total_growth: float) -> void:
	if _ball_powerup != null:
		_ball_powerup.record_stats(kills, total_growth)
