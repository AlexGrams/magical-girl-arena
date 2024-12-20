class_name PlayerCharacterBody2D
extends CharacterBody2D

@export var level_shoot_intervals:Array
@export var speed = 400
@onready var bullet_scene = preload("res://Powerups/bullet.tscn")
var shoot_powerup_path = "res://Powerups/shooting_powerup.tscn"
var shoot_timer = 0
var shoot_interval = 1
var experience = 0
var health_max = 100
var health = health_max
var level = 1

signal took_damage(health:int, health_max:int)
signal gained_experience(experience: float, level: int)


func _ready():
	took_damage.emit(health, health_max)
	
	# Each player tells the local GameState that it has spawned in
	GameState.add_player_character(self)


func _on_upgrade_chosen(powerup_name):
	var powerup_found = false
	for child in get_children():
		if child is Powerup and child.powerup_name == powerup_name:
			child.level_up()
			powerup_found = true
			break
	if !powerup_found:
		var powerup_to_add
		match powerup_name:
			"Boomerang":
				powerup_to_add = load("res://Powerups/boomerang_powerup.tscn").instantiate()
			"Revolving":
				powerup_to_add = load("res://Powerups/revolving_powerup.tscn").instantiate()
			"Orbit":
				powerup_to_add = load("res://Powerups/orbit_powerup.tscn").instantiate()
		powerup_to_add.set_authority(multiplayer.get_unique_id())
		add_child(powerup_to_add)
		powerup_to_add.activate_powerup()
		
	$"../CanvasLayer/UpgradeScreenPanel".hide()
	GameState.player_selected_upgrade.rpc_id(1)


func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed


func _process(_delta: float) -> void:
	var direction = get_global_mouse_position() - $Sprite2D.global_position
	var direction_normal = direction.normalized()
	$Line2D.points = [direction_normal*100, Vector2.ZERO]


func _physics_process(_delta):
	if is_multiplayer_authority():
		get_input()
		move_and_slide()


# Deal damage to the player
func take_damage(damage: float) -> void:
	health -= damage
	took_damage.emit(health, health_max)
	$AnimationPlayer.play("took_damage")
	if health <= 0:
		get_tree().paused = true
		$".".hide()


func set_label_name(new_name: String) -> void:
	$Label.text = new_name


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(2): #If Enemy
		take_damage(10)
	elif area.get_collision_layer_value(6): #If Enemy Bullet:
		take_damage(area.damage)
	elif area.get_collision_layer_value(3): #If EXP Orb
		if is_multiplayer_authority():
			GameState.collect_exp.rpc()
			if area.get_parent() != null:
				area.get_parent().destroy.rpc_id(1)


# Sets up this character on this game instance after it is spawned.
# Should be called only once, like with _ready().
@rpc("any_peer", "call_local")
func ready_local_player() -> void:
	# Should not be called on characters that are not owned by this game instance.
	if not is_multiplayer_authority():
		return
	
	gained_experience.connect($"../CanvasLayer"._on_character_body_2d_gained_experience)
	
	# Should redo this in the future prob?
	$"../CanvasLayer/UpgradeScreenPanel".upgrade_chosen.connect(_on_upgrade_chosen)
	
	# Give the player the basic shoot powerup.
	# Only the character that this player controls is given the ability. 
	var shoot_powerup = load(shoot_powerup_path).instantiate()
	add_child(shoot_powerup)
	shoot_powerup.activate_powerup()


@rpc("any_peer", "call_local")
func teleport(new_position: Vector2) -> void:
	self.position = new_position


@rpc("any_peer", "call_local")
func set_authority(id: int) -> void:
	set_multiplayer_authority(id)


# Makes this player's view follow this character.
@rpc("authority", "call_local")
func set_camera_current() -> void:
	$Camera2D.make_current()


# Emits the signal for gaining experience on all clients.
@rpc("any_peer", "call_local")
func emit_gained_experience(new_experience: float, new_level: int):
	if not is_multiplayer_authority():
		return
	
	experience = new_experience
	level = new_level
	
	gained_experience.emit(float(experience) / GameState.level_exp_needed[level-1], level)


# TODO: Disabled. Code solution if physics solution doesn't work out.
# Causes EXP orbs to gravitate towards the player when they enter this area.
#func _on_exp_pickup_area_2d_area_entered(area: Area2D) -> void:
	#if area.get_collision_layer_value(3):
		#area.get_parent().set_player(self)
