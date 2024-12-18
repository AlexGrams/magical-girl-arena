extends Node2D

class_name Enemy

@export var max_health: float = 100
@export var health: float = 100

var player: Node2D = null
var speed: float = 100
@onready var exp_scene = preload("res://exp_orb.tscn")

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if player != null:
		global_position = global_position.move_toward(player.global_position, delta*speed)
	else:
		player = get_nearest_player_character()


# Find the player that is closest to this enemy 
func get_nearest_player_character() -> Node2D:
	var nearest_player: Node2D = null
	var nearestDist: float = -1.0
	var currentDist: float = 0.0
	
	for player_character in GameState.player_characters:
		currentDist = global_position.distance_squared_to(player_character.global_position)
		if currentDist < nearestDist or nearestDist < -0.5:
			nearestDist = currentDist
			nearest_player = player_character
	
	return nearest_player


func take_damage(damage: float) -> void:
	health -= damage
	$AnimationPlayer.play("take_damage")
	if health <= 0 and is_multiplayer_authority():
		die.rpc_id(1)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is BulletHitbox:
		take_damage(area.damage)


@rpc("any_peer", "call_local")
func die() -> void:
	var exp_orb = exp_scene.instantiate()
	exp_orb.global_position = global_position
	get_tree().root.call_deferred("add_child", exp_orb)
	queue_free()
