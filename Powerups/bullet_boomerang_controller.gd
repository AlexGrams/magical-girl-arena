class_name BulletBoomerangController
extends Bullet
## Manages sending out multiple bullet_boomerang objects. The boomerang bullets are spawned by
## this object, but both the controller and the boomerangs destroy themselves separately when 
## this powerup is deactivated.
## Boomerang management logic is performed separately on each client. No RPCs are used to
## communicate which boomerang is targeting which enemy. I'm just hoping that each boomerang
## behaves about the same on each client. 


## The bullet object is replicated on all clients.
## This owner is the client's replicated version of the character that owns this bullet.
var boomerang_owner: Node2D = null

## Instantiated boomerangs. Only has elements in the server's replication of this object.
var _boomerangs: Array[BulletBoomerang] = []
## Queue of boomerangs that are idle and have no target.
var _ready_boomerangs: Array[BulletBoomerang] = []
var _boomerang_owner_path: NodePath = ""
## Time in seconds between when Boomerangs are sent out at enemies.
var _fire_interval: float = 0.0
## Time until next boomerang firing.
var _fire_timer: float = 0.0
## The actual bullet that does damage for the Boomerang powerup.
var _boomerang_bullet_scene: String = ""
## How much damage each boomerang does
var _damage: float = 0.0
var _powerup_level: int = 1
## Properties for analytics
var _owner_id: int = -1
var _powerup_index: int = -1


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _powerup_level < 3:
		# Rapid fire boomerangs
		if len(_ready_boomerangs) > 0:
			if _ready_boomerangs[0].find_new_target():
				_ready_boomerangs.pop_front()
	else:
		# Wait a little bit in between firing boomerangs.
		_fire_timer += delta
		if _fire_timer >= _fire_interval and len(_ready_boomerangs) > 0:
			_fire_timer = 0.0
			if _ready_boomerangs[0].find_new_target():
				_ready_boomerangs.pop_front()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 3
		or typeof(data[0]) != TYPE_NODE_PATH	# Owning character 
		or typeof(data[1]) != TYPE_FLOAT 		# Fire rate
		or typeof(data[2]) != TYPE_STRING		# Path to actual Boomerang bullet.
	):
		push_error("Malformed data array")
		return
	
	boomerang_owner = get_tree().root.get_node(data[0])
	_boomerang_owner_path = data[0]
	_fire_interval = data[1]
	_boomerang_bullet_scene = data[2]
	_is_owned_by_player = is_owned_by_player
	
	# Spawn the boomerangs.
	if is_multiplayer_authority():
		_spawn_boomerang()
		if _powerup_level >= 3:
			_spawn_boomerang()
			_spawn_boomerang()
	
	# Connect signals.
	if is_owned_by_player:
		# When the player levels up this powerup, notify all clients about the level up.
		var boomerang_powerup := boomerang_owner.get_node_or_null("PowerupBoomerang")
		# The Powerup child is not replicated, so only the client which owns this character has it.
		if boomerang_powerup != null:
			boomerang_powerup.set_boomerang_controller(self)
			boomerang_powerup.powerup_level_up.connect(func(new_level: int, new_damage: float):
				level_up.rpc(new_level, new_damage)
			)
	
		# When the owner goes down, destroy this bullet
		boomerang_owner.died.connect(func():
			queue_free()
		)
	else:
		# TODO: Not implemented
		pass


func set_damage(damage: float, _is_crit: bool = false):
	_damage = damage


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	_owner_id = owner_id
	_powerup_index = powerup_index


func _spawn_boomerang() -> void:
	var spawned_bullet = get_tree().root.get_node("Playground/BulletSpawner").spawn(
		[_boomerang_bullet_scene, 
			boomerang_owner.global_position, 
			Vector2.UP, 
			_damage, 
			false,
			_is_owned_by_player,
			_owner_id,
			_powerup_index,
			[_boomerang_owner_path, self.get_path()]
		]
	)
	spawned_bullet.setup_analytics(_owner_id, _powerup_index)
	_boomerangs.append(spawned_bullet)


## Add a boomerang that is ready to fire to our list of boomerangs
func add_ready_boomerang(boomerang: BulletBoomerang) -> void:
	_ready_boomerangs.append(boomerang)


## This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(new_level: int, new_damage: float):
	_powerup_level = new_level
	_damage = new_damage
	
	if is_multiplayer_authority() and new_level == 3:
		_spawn_boomerang()
		_spawn_boomerang()


## Turn on signature functionality for all Boomerangs. Only call on server.
@rpc("any_peer", "call_local")
func activate_signature() -> void:
	for boomerang: BulletBoomerang in _boomerangs:
		boomerang.make_bigger.rpc()


func boost() -> void:
	for boomerang: BulletBoomerang in _boomerangs:
		boomerang.boost.rpc()


func unboost() -> void:
	for boomerang: BulletBoomerang in _boomerangs:
		boomerang.unboost.rpc()
