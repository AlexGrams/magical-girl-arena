extends Bullet
## Manages sending out multiple bullet_boomerang objects. The boomerang bullets are spawned by
## this object, but both the controller and the boomerangs destroy themselves separately when 
## this powerup is deactivated.


## How close the Boomerang needs to get to its destination before switching directions.
const touching_distance_threshold: float = 30.0

## Target enemy must be within this range
@export var max_range: float = 750

## The bullet object is replicated on all clients.
## This owner is the client's replicated version of the character that owns this bullet.
var boomerang_owner: Node2D = null
var farthest_enemy: Node
var is_returning := true

@onready var _squared_touching_distance_threshold: float = touching_distance_threshold ** 2
## When owned by an Enemy, the location that the bullet to moving towards away from its owner. 
var _target_location := Vector2.ZERO
## Time in seconds between when Boomerangs are sent out at enemies.
var _fire_interval: float = 0.0
## The actual bullet that does damage for the Boomerang powerup.
var _boomerang_bullet_scene: String = ""
## How much damage each boomerang does
var _damage: float = 0.0
## Properties for analytics
var _owner_id: int = -1
var _powerup_index: int = -1


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


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
	_fire_interval = data[1]
	_boomerang_bullet_scene = data[2]
	_is_owned_by_player = is_owned_by_player
	
	# TODO: Spawn boomerangs depending on what powerup level we are.
	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [_boomerang_bullet_scene, 
			global_position, 
			Vector2.UP, 
			_damage, 
			_is_owned_by_player,
			_owner_id,
			_powerup_index,
			[data[0]]
		]
	)
	
	if is_owned_by_player:
		# When the player levels up this powerup, notify all clients about the level up.
		var boomerang_powerup := boomerang_owner.get_node_or_null("BoomerangPowerup")
		# The Powerup child is not replicated, so only the client which owns this character has it.
		if boomerang_powerup != null:
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


func set_damage(damage:float):
	_damage = damage


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	_owner_id = owner_id
	_powerup_index = powerup_index


## This bullet's owner has leveled up this bullet's corresponding powerup
@rpc("any_peer", "call_local")
func level_up(new_level: int, new_damage: float):
	if new_level == 3:
		# TODO: Make two more bullets.
		_damage = new_damage
