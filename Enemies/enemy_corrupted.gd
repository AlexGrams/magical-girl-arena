class_name EnemyCorrupted
extends EnemyRanged
# A corrupted magical girl enemy. Can use powerups and abilities like the player.

## How long this corrupted enemy stays in the game before leaving. Doesn't drop loot if time runs out.
@export var corrupted_lifetime: float = 0.0
## Scene for the Powerup to give to this enemy when it spawns.
@export var default_powerup := ""

# How much time this corrupted enemy has left in the game.
var current_lifetime: float = 0.0


func _ready() -> void:
	super()
	
	current_lifetime = corrupted_lifetime
	
	if default_powerup != "":
		_add_powerup(default_powerup)


func _process(delta: float) -> void:
	super(delta)
	
	current_lifetime -= delta
	if current_lifetime <= 0.0 and is_multiplayer_authority():
		_leave()


func _physics_process(delta: float) -> void:
	super(delta)


func shoot() -> void:
	var direction = target.global_position - self.global_position
	direction = direction.normalized()

	get_tree().root.get_node("Playground/BulletSpawner").request_spawn_bullet.rpc_id(
		1, [null, 
			global_position, 
			direction, 
			bullet_damage, 
			[]
		]
	)


# Despawn the corrupted enemy. Different from dying as it doesn't drop loot.
@rpc("any_peer", "call_local")
func _leave() -> void:
	if not is_multiplayer_authority():
		return
	
	queue_free()
