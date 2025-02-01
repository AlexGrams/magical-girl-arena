class_name PlayerCharacterBody2D
extends CharacterBody2D

# How long this player has to wait before being able to be revived.
const TIME_BEFORE_PLAYER_CAN_BE_REVIVED: float = 5.0
# How long another player must spend reviving this player.
const TIME_TO_REVIVE: float = 3.0
# Index of the collision layer for players.
const PLAYER_COLLISION_LAYER: int = 4
# The most number of different powerups that this player can have INCLUDING the base shooting powerup.
const MAX_POWERUPS = 4

@export var level_shoot_intervals:Array
@export var speed = 400
@export var _player_collision_area: Area2D = null
@export var _revive_collision_area: Area2D = null
@export var _revive_progress_bar: TextureProgressBar = null
@onready var bullet_scene = preload("res://Powerups/bullet.tscn")
var shoot_powerup_path = "res://Powerups/shooting_powerup.tscn"
# All powerups that this player has.
var powerups: Array[Powerup] = []
# All Abilities that this player has.
# Index 0 is the ultimate, and higher indicies are the regular abilities.
var abilities: Array[Ability] = []
var shoot_timer = 0
var shoot_interval = 1
var experience = 0
var health_max = 100
var health = health_max
# True when the player is incapacitated.
var is_down := false
# How long the player has been downed for. When time is up, this player can be revived.
var down_timer: float = 0.0
var revive_timer: float = 0.0
var level = 1

signal took_damage(health:int, health_max:int)
signal gained_experience(experience: float, level: int)
signal died()
signal revived()


func _ready():
	_revive_collision_area.hide()


func _on_upgrade_chosen(powerup_name):
	var powerup_found = false
	
	# Upgrade the chosen powerup if we already have it.
	for child in get_children():
		if child is Powerup and child.powerup_name == powerup_name:
			child.level_up()
			powerup_found = true
			break
	
	# If we don't have the chosen powerup, then add it to the player.
	if !powerup_found:
		var powerup_to_add
		match powerup_name:
			"Boomerang":
				powerup_to_add = load("res://Powerups/boomerang_powerup.tscn").instantiate()
			"Revolving":
				powerup_to_add = load("res://Powerups/revolving_powerup.tscn").instantiate()
			"Orbit":
				powerup_to_add = load("res://Powerups/orbit_powerup.tscn").instantiate()
		add_powerup(powerup_to_add)


func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != null:
		velocity = input_direction * speed


func _process(delta: float) -> void:
	var direction = get_global_mouse_position() - $Sprite2D.global_position
	var direction_normal = direction.normalized()
	$Line2D.points = [direction_normal*100, Vector2.ZERO]
	
	# Death and reviving
	if is_down:
		if down_timer < TIME_BEFORE_PLAYER_CAN_BE_REVIVED:
			down_timer += delta
			
			if down_timer >= TIME_BEFORE_PLAYER_CAN_BE_REVIVED:
				_revive_progress_bar.value = 0.0
			else:
				_revive_progress_bar.value = down_timer / TIME_BEFORE_PLAYER_CAN_BE_REVIVED
		elif revive_timer < TIME_TO_REVIVE:
			if _revive_collision_area.has_overlapping_areas():
				revive_timer += delta
				if revive_timer >= TIME_TO_REVIVE:
					revive()
			else:
				revive_timer = max(revive_timer - delta, 0.0)
			
			_revive_progress_bar.value = revive_timer / TIME_TO_REVIVE


func _physics_process(_delta):
	if not is_down and is_multiplayer_authority():
		get_input()
		move_and_slide()


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if is_down:
		return
	
	if event.is_action_pressed("ability_ultimate") and abilities[0].get_can_activate():
		abilities[0].activate()


# Gives this player a new powerup.
func add_powerup(powerup: Powerup):
	powerup.set_authority(multiplayer.get_unique_id())
	add_child(powerup)
	powerups.append(powerup)
	
	if not is_down:
		powerup.activate_powerup()


# Enable all equipped powerups.
func enable_powerups():
	for powerup: Powerup in powerups:
		powerup.activate_powerup()


# Deactivate all equipped powerups.
func disable_powerups():
	for powerup: Powerup in powerups:
		powerup.deactivate_powerup()


# Deal damage to the player. Should be RPC'd on everyone.
@rpc("authority", "call_local")
func take_damage(damage: float) -> void:
	if is_down:
		return
	
	health = clamp(health - damage, 0, health_max)
	took_damage.emit(health, health_max)
	
	if damage > 0:
		$AnimationPlayer.play("took_damage")
		if health <= 0:
			die()


# The player becomes incapacitated. Their abilities no longer work, and they must wait some
# time before being able to be revived by another player. If no players remain, then the
# game is over.
func die():
	is_down = true
	down_timer = 0.0
	revive_timer = 0.0
	_revive_collision_area.show()
	_player_collision_area.set_collision_layer_value(PLAYER_COLLISION_LAYER, false)
	
	disable_powerups()
	died.emit()


# The player has been picked back up by another player.
func revive():
	is_down = false
	_revive_collision_area.hide()
	_player_collision_area.set_collision_layer_value(PLAYER_COLLISION_LAYER, true)
	take_damage(-health_max)
	
	enable_powerups()
	revived.emit()


func set_label_name(new_name: String) -> void:
	$Label.text = new_name


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	# NOTE: Only clients have authority over when they take damage.
	# The client takes damage only when they see themselves hit an enemy on their screen.
	# This means the server doesn't have authority over when anyone else takes damage.
	# take_damage needs to be RPC'd on all clients to help synchronize living/dead state.
	# Some side effects include:
	# - Multiple players can take damage from the same projectile if it isn't destroyed
	#   on time.
	# - Clients can see another player not take damage from an enemy, despite them touching
	#   on their screen. This is because the other player didn't hit the enemy from their
	#   POV, so the collision didn't happen.
	
	if area.get_collision_layer_value(2): #If Enemy
		pass
		#take_damage.rpc(10)
	elif area.get_collision_layer_value(6): #If Enemy Bullet:
		take_damage.rpc(area.damage)
		area.get_parent().request_delete.rpc_id(1)


# Tells this client's GameState which ID goes with which local player node instance.
@rpc("any_peer", "call_local")
func register_with_game_state(owning_player_id: int) -> void:
	GameState.add_player_character(owning_player_id, self)


# Sets up this character on this game instance after it is spawned.
# Should be called only once, like with _ready().
@rpc("any_peer", "call_local")
func ready_local_player() -> void:
	# Should not be called on characters that are not owned by this game instance.
	if not is_multiplayer_authority():
		return
	
	# Signal for experience changes
	gained_experience.connect($"../CanvasLayer"._on_character_body_2d_gained_experience)
	
	# Signal for health changes
	took_damage.connect($"../CanvasLayer"._on_character_body_2d_took_damage)
	took_damage.emit(health, health_max)
	
	# Should redo this in the future prob?
	$"../CanvasLayer/UpgradeScreenPanel".upgrade_chosen.connect(_on_upgrade_chosen)
	
	# Give the player the basic shoot powerup.
	# Only the character that this player controls is given the ability. 
	var shoot_powerup = load(shoot_powerup_path).instantiate()
	add_powerup(shoot_powerup)
	
	# Set up ultimate ability
	# TODO: Testing ults using Goth ult only.
	var ult: Ability = preload("res://Abilities/ability_ult_goth.tscn").instantiate()
	ult.set_authority(multiplayer.get_unique_id())
	add_child(ult)
	abilities.append(ult)


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
	
	gained_experience.emit(float(experience) / GameState.exp_for_next_level, level)


# Causes EXP orbs to gravitate towards the player when they enter this area.
func _on_exp_pickup_area_2d_area_entered(area: Area2D) -> void:
	if multiplayer.is_server() and area.get_collision_layer_value(3):
		area.get_parent().set_player.rpc(self.get_path())
