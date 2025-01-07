extends Powerup

var bullet_scene := "res://Powerups/orbit_bullet.tscn"
var sprite = preload("res://Coconut.png")
var bullet
var powerup_name := "Orbit"

signal picked_up_powerup(sprite)


func _ready() -> void:
	damage_levels = [20.0, 25.0, 25.0, 25.0, 100.0]


func activate_powerup():
	# TODO: Fix jank with how the orbit bullet is spawned.
	# What's unique about this bullet is that it is parented to a player instead of
	# the Playground.
	# What will be done instead:
	# 1. Spawning using the same bullet spawner as everyone else.
	# 2. It will instead manually calculate the orbit by setting its center position to
	#    that of the player instead of using parenting.
	# 3. The bullet needs to know which player character to orbit. Therefore we will
	#    use the args array to pass the owner's unique ID. The server then maps the ID
	#    to a character instance. We will need a new object on GameState that maps
	#    player unique ID to character. Make sure to reset this variable as well on game
	#    reset.
	get_parent().get_node("BulletSpawner").request_spawn_bullet.rpc_id(
		1,
		[
			bullet_scene, 
			Vector2.ZERO, 
			Vector2.ZERO, 
			damage_levels[min(damage_levels.size() - 1, current_level)], 
			[]
		]
	)
	
	picked_up_powerup.emit(sprite)


func deactivate_powerup():
	pass


func level_up():
	current_level += 1
	powerup_level_up.emit(current_level, damage_levels[min(damage_levels.size() - 1, current_level)])
