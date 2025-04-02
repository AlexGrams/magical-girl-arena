class_name PlayerCharacterBody2D
extends CharacterBody2D

# How long this player has to wait before being able to be revived.
const TIME_BEFORE_PLAYER_CAN_BE_REVIVED: float = 5.0
# How long another player must spend reviving this player.
const TIME_TO_REVIVE: float = 3.0
# Index of the collision layer for players.
const PLAYER_COLLISION_LAYER: int = 4
# The most number of different powerups that this player can have INCLUDING their base powerup.
const MAX_POWERUPS: int = 5
# How many rerolls this player is given at the start of the game.
const STARTING_REROLLS: int = 3
# How long temporary health stays on the player before going away.
const TEMP_HEALTH_LINGER_TIME: float = 5.0
# Time in seconds between health regen ticks
const HEALTH_REGEN_INTERVAL: float = 5.0

@export var level_shoot_intervals:Array
@export var speed = 400
# Maps string name of character to their CharacterData resource file
@export var _character_data: Dictionary = {}
@export var _player_collision_area: Area2D = null
@export var _pickup_area: Area2D = null
@export var _revive_collision_area: Area2D = null
@export var _revive_progress_bar: TextureProgressBar = null
@export var _on_screen_notifier: VisibleOnScreenNotifier2D = null
@export var _gdcubism_user_model: GDCubismUserModel = null

@onready var bullet_scene = preload("res://Powerups/bullet.tscn")
var shoot_powerup_path = "res://Powerups/shooting_powerup.tscn"
# All powerups that this player has.
var powerups: Array[Powerup] = []
# All Abilities that this player has.
# Index 0 is the ultimate, and higher indicies are the regular abilities.
var abilities: Array[Ability] = []
var shoot_timer = 0
var shoot_interval = 1
var level = 1
var experience = 0

var health_max: int = 100
var health: int = health_max
# True when the player is incapacitated.
var is_down := false
# How long the player has been downed for. When time is up, this player can be revived.
var down_timer: float = 0.0
var revive_timer: float = 0.0

# Temporary HP that goes away after some time
var _temp_health: int = 0
# How long until temp HP automatically disappears.
var _temp_health_timer: float = 0.0
# How much health is recovered per health regen tick.
var _health_regen: float = 0.0
# How long until the next health regen tick.
var _health_regen_timer: float = 0.0
# Number of remaining powerup rerolls. Not replicated.
var _rerolls: int = STARTING_REROLLS
# Temporary rerolls that only become available in rare situations, and can only be used for one levelup.
var _temp_rerolls: int = 0
# Stat levels
var _stat_health: int = 1
var _stat_health_regen: int = 1
var _stat_speed: int = 1
var _stat_pickup_radius: int = 1
var _stat_damage: int = 1
var _stat_ultimate_damage: int = 1
var _stat_ultimate_charge_rate: int = 1

signal took_damage(health:int, health_max:int, temp_health: int)
signal gained_experience(experience: float, level: int)
signal died()
signal revived()


func _ready():
	_revive_collision_area.hide()


func _on_upgrade_chosen(powerup_data: PowerupData):
	var powerup_found = false
	
	# Reset temp rerolls in case we have any
	_temp_rerolls = 0
	
	# Upgrade the chosen powerup if we already have it.
	for child in get_children():
		if child is Powerup and child.powerup_name == powerup_data.name:
			child.level_up()
			$"..".get_hud_canvas_layer().update_powerup_level(powerup_data, child.current_level)
			
			powerup_found = true
			break
	
	# If we don't have the chosen powerup, then add it to the player.
	if !powerup_found:
		add_powerup(powerup_data)


## Upgrade stats depending on which upgrade was chosen
func _on_stat_upgrade_chosen(stat_type: Constants.StatUpgrades) -> void:
	match stat_type:
		Constants.StatUpgrades.HEALTH:
			_stat_health += 1
			# TODO: Temporary for now. Figure out if we want to do this off a curve or something.
			health_max += 10
			take_damage(-10.0)
		Constants.StatUpgrades.HEALTH_REGEN:
			_stat_health_regen += 1
			_health_regen += 1.0
		Constants.StatUpgrades.SPEED:
			_stat_speed += 1
			speed += 40
		Constants.StatUpgrades.PICKUP_RADIUS:
			_stat_pickup_radius += 1
			_pickup_area.scale += Vector2(0.1, 0.1)
		Constants.StatUpgrades.DAMAGE:
			_stat_damage += 1
		Constants.StatUpgrades.ULTIMATE_DAMAGE:
			_stat_ultimate_damage += 1
		Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
			_stat_ultimate_charge_rate += 1
		_:
			push_error("No upgrade functionality for this stat upgrade type")


## Returns the current level of a player's stat given the stat enum type.
func get_stat(stat_type: Constants.StatUpgrades) -> int:
	match stat_type:
		Constants.StatUpgrades.HEALTH:
			return _stat_health
		Constants.StatUpgrades.HEALTH_REGEN:
			return _stat_health_regen
		Constants.StatUpgrades.SPEED:
			return _stat_speed
		Constants.StatUpgrades.PICKUP_RADIUS:
			return _stat_pickup_radius
		Constants.StatUpgrades.DAMAGE:
			return _stat_damage
		Constants.StatUpgrades.ULTIMATE_DAMAGE:
			return _stat_ultimate_damage
		Constants.StatUpgrades.ULTIMATE_CHARGE_RATE:
			return _stat_ultimate_charge_rate
		_:
			push_error("No upgrade functionality for this stat upgrade type")
	return 1


func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != null:
		velocity = input_direction * speed


func _process(delta: float) -> void:
	var direction = get_global_mouse_position() - $Sprite2D.global_position
	var direction_normal = direction.normalized()
	$Line2D.points = [direction_normal*100, Vector2.ZERO]
	
	# Health regen - ticks at every interval, but does nothing if it ticks when health is full
	if _health_regen > 0.0:
		_health_regen_timer -= delta
		if _health_regen_timer <= 0.0:
			# Add health
			take_damage(-_health_regen)
			_health_regen_timer = HEALTH_REGEN_INTERVAL
	
	# Temporary health is reset after some time has passed.
	if _temp_health_timer > 0.0:
		_temp_health_timer -= delta
		if _temp_health_timer <= 0.0:
			_temp_health = 0
			took_damage.emit(health, health_max, _temp_health)
	
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


func get_rerolls() -> int:
	return _rerolls + _temp_rerolls


func increment_temp_rerolls() -> void:
	_temp_rerolls += 1


func decrement_rerolls() -> void:
	if _temp_rerolls > 0:
		_temp_rerolls -= 1
	else:
		_rerolls -= 1


# Gives this player a new powerup.
func add_powerup(powerup_data: PowerupData):
	var powerup: Powerup = powerup_data.scene.instantiate()
	powerup.set_authority(multiplayer.get_unique_id())
	add_child(powerup)
	powerups.append(powerup)
	
	# Show the icon for this powerup on the HUD
	$"..".get_hud_canvas_layer().add_powerup(powerup_data)
	
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
	
	if damage > 0:
		# Deplete temp health before regular health.
		# Skip this if the player is gaining health instead.
		if _temp_health > 0:
			_temp_health -= damage
			
			if _temp_health < 0:
				# Temporary health was delepeted
				damage = abs(_temp_health)
				_temp_health = 0
				_temp_health_timer = 0.0
			else:
				damage = 0
	
	health = clamp(health - damage, 0, health_max)
	took_damage.emit(health, health_max, _temp_health)
	
	if damage > 0:
		$AnimationPlayer.play("took_damage")
		if health <= 0:
			die()


# Add temporary health to the player
@rpc("any_peer", "call_local")
func add_temp_health(temp_health_to_add: int) -> void:
	if is_down: 
		return
	
	_temp_health += temp_health_to_add
	_temp_health_timer = TEMP_HEALTH_LINGER_TIME
	
	took_damage.emit(health, health_max, _temp_health)


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
		if area.get_parent() != null and area.get_parent().has_method("request_delete"):
			area.get_parent().request_delete.rpc_id(1)


# Tells this client's GameState which ID goes with which local player node instance.
@rpc("any_peer", "call_local")
func register_with_game_state(owning_player_id: int) -> void:
	GameState.add_player_character(owning_player_id, self)


# Sets up this character after it is spawned. Has different behavior depending on if this
# function is called on the character this client controls. 
# Should be called only once, like with _ready().
@rpc("any_peer", "call_local")
func ready_player_character(character: Constants.Character) -> void:
	# Set the character's appearance
	var character_data: CharacterData = null
	match character:
		Constants.Character.GOTH:
			character_data = _character_data["Goth"]
		Constants.Character.SWEET:
			character_data = _character_data["Sweet"]
	
	_gdcubism_user_model.set_assets(character_data.model_file_path)
	
	# Should not be called on characters that are not owned by this game instance.
	if is_multiplayer_authority():
		# Signal for experience changes
		gained_experience.connect($"../CanvasLayer"._on_character_body_2d_gained_experience)
		
		# Signal for health changes
		took_damage.connect($"../CanvasLayer"._on_character_body_2d_took_damage)
		took_damage.emit(health, health_max, _temp_health)
		
		# Powerup upgrade buttons
		$"../CanvasLayer/UpgradeScreenPanel".upgrade_chosen.connect(_on_upgrade_chosen)
		# Stat upgrade buttons
		$"../CanvasLayer/UpgradeScreenPanel".stat_upgrade_chosen.connect(_on_stat_upgrade_chosen)
		
		# Give the player the basic shoot powerup.
		# Only the character that this player controls is given the ability. 
		var base_powerup_data: PowerupData = load(character_data.base_powerup_data) 
		add_powerup(base_powerup_data)
		
		# Set up ultimate ability
		var ult: Ability = load(character_data.ultimate_ability).instantiate()
		ult.set_authority(multiplayer.get_unique_id())
		add_child(ult)
		abilities.append(ult)
		$"..".get_hud_canvas_layer().set_up_ultimate_ui(character_data, ult)
	else:
		# This client does not own this PlayerCharacter. Connect events to show the
		# pointer to this character when it goes off screen for the local client.
		get_tree().root.get_node("Playground/CanvasLayer").add_character_to_point_to(_on_screen_notifier)


@rpc("any_peer", "call_local")
func teleport(new_position: Vector2) -> void:
	self.position = new_position


# Sets multiplayer authority and other values for this character.
@rpc("any_peer", "call_local")
func setup_authority(id: int, character: Constants.Character) -> void:
	# TODO: There might be a bug that happens if this funciton is called before the character enters
	# the tree. Need to test.
	set_multiplayer_authority(id)
	ready_player_character(character)
	
	# Extra functionality if this client is being given authority to its own character.
	if id == multiplayer.get_unique_id():
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
