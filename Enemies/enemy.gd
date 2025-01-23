extends Node2D

class_name Enemy

@export var max_health: float = 100
@export var health: float = 100

var player: PlayerCharacterBody2D = null
var speed: float = 100
@onready var exp_scene = preload("res://Pickups/exp_orb.tscn")

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if player != null:
		global_position = global_position.move_toward(player.global_position, delta*speed)
	else:
		_find_new_target()


# Set player that this enemy is trying to attack. 
# Makes sure to find a new target if the current one dies.
func _find_new_target() -> void:
	player = get_nearest_player_character()
	if player != null:
		player.died.connect(func():
			player = null
		)


# Find the player that is closest to this enemy 
func get_nearest_player_character() -> PlayerCharacterBody2D:
	var nearest_player: PlayerCharacterBody2D = null
	var nearestDist: float = -1.0
	var currentDist: float = 0.0
	
	for player_character: PlayerCharacterBody2D in GameState.player_characters.values():
		if player_character != null and not player_character.is_down:
			currentDist = global_position.distance_squared_to(player_character.global_position)
			if currentDist < nearestDist or nearestDist < -0.5:
				nearestDist = currentDist
				nearest_player = player_character
	
	return nearest_player


func take_damage(damage: float) -> void:
	print((multiplayer.get_unique_id()), str(damage))
	health -= damage
	$AnimationPlayer.play("take_damage")
	if health <= 0 and is_multiplayer_authority():
		die.rpc_id(1)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is BulletHitbox:
		take_damage(area.damage)


# Delete this enemy and spawn EXP orbs. Only call on the server.
@rpc("any_peer", "call_local")
func die() -> void:
	if not is_multiplayer_authority():
		return
	
	var exp_orb = exp_scene.instantiate()
	exp_orb.global_position = global_position
	get_tree().root.get_node("Playground").call_deferred("add_child", exp_orb, true)
	queue_free()
