class_name Enemy
extends CharacterBody2D

const curve_max_health: Curve = preload("res://Curves/enemy_max_health.tres")

# Parent of this Enemy's collider
@export var collider_area: Area2D = null
@export var sprite: Sprite2D = null
# Time in seconds between when this Enemy can attack
@export var attack_interval: float = 1.0
@export var attack_damage: float = 10.0
# The relative liklihoods of dropping EXP, gold, or nothing when this Enemy dies.
@export var drop_weight_exp: float = 1.0
@export var drop_weight_gold: float = 1.0
@export var drop_weight_nothing: float = 1.0


@onready var exp_scene = preload("res://Pickups/exp_orb.tscn")
@onready var gold_scene = preload("res://Pickups/gold.tscn")
@onready var damage_indicator_scene = preload("res://UI/damage_indicator.tscn")

# Max health is set based off of the current time when this enemy spawns.
var max_health: int = 0
var health: int = 0
# The character that this Enemy is trying to attack.
var target: Node2D = null
# All Objects that this Enemy can damage that it is touching right now.
var colliding_targets: Array[Node2D] = []
# Movement speed of this Enemy
var speed: float = 100
# True if it tries to harm Enemies instead of players.
var is_ally := false
# How long this Enemy lasts as an ally before being destroyed
var lifetime: float = 0.0
# Damage this Enemy does to other Enemies when it is an ally.
var ally_damage: float = 0.0

# How long until this Enemy can attack again
var _attack_timer: float = 0.0
# Thresholds used for randomly determining what an enemy drops. 
var _threshold_exp: float = 0.0
var _threshold_gold: float = 0.0

# Emitted when this Enemy dies.
signal died(enemy: Enemy)
# Emitted when this Enemy is converted to an ally.
signal allied(enemy: Enemy)


func _ready() -> void:
	max_health = snapped(curve_max_health.sample(GameState.get_game_progress_as_fraction()), 1)
	health = max_health
	
	# Random loot generation
	var total := drop_weight_exp + drop_weight_gold + drop_weight_nothing
	_threshold_exp = drop_weight_exp / total
	_threshold_gold = drop_weight_gold / total + _threshold_exp


func _process(delta: float) -> void:
	# Attack if possible
	if _attack_timer > 0:
		_attack_timer -= delta
	elif len(colliding_targets) > 0:
		if not is_ally:
			for node: PlayerCharacterBody2D in colliding_targets:
				node.take_damage.rpc(attack_damage)
		else:
			for node in colliding_targets:
				if node != null and not node.is_queued_for_deletion():
					node.take_damage(ally_damage)
		
		_attack_timer = attack_interval
	
	if is_ally:
		lifetime -= delta
		if lifetime <= 0.0:
			take_damage(health)


func _physics_process(_delta: float) -> void:
	if target != null:
		velocity = (target.global_position - global_position).normalized() * speed
		move_and_slide()
	else:
		_find_new_target()


# Spawn in and add a Powerup to this Enemy. The Powerup may need extra functionality to 
# account for it not being on the Player. Only call on the server.
func _add_powerup(powerup_scene_path: String) -> void:
	if not multiplayer.is_server():
		return
	
	var powerup: Powerup = load(powerup_scene_path).instantiate()
	powerup.set_authority(get_multiplayer_authority())
	add_child(powerup)
	powerup.activate_powerup()


# Set target that this enemy is trying to attack. 
# Makes sure to find a new target if the current one dies.
func _find_new_target() -> void:
	if not is_ally:
		target = get_nearest_player_character()
		if target != null:
			target.died.connect(func():
				target = null
			)
	else:
		# Alternate behavior, for when this Enemy attacks other Enemies.
		target = get_nearest_hostile_enemy()
	
		if target != null:
			# Bind death and allied events.
			# NOTE: There is a slight bug where the "died" signal will still be bound 
			# if the Enemy switches target due to the "allied" signal being called.
			# Shouldn't make much of a difference.
			target.died.connect(func(_enemy: Enemy):
				_find_new_target()
			, CONNECT_ONE_SHOT)
			target.allied.connect(func(_enemy: Enemy):
				_find_new_target()
			, CONNECT_ONE_SHOT)


# Find the player that is closest to this enemy 
func get_nearest_player_character() -> PlayerCharacterBody2D:
	var nearest_player: PlayerCharacterBody2D = null
	var nearest_dist: float = -1.0
	var current_dist: float = 0.0
	
	for player_character: PlayerCharacterBody2D in GameState.player_characters.values():
		if player_character != null and not player_character.is_down:
			current_dist = global_position.distance_squared_to(player_character.global_position)
			if current_dist < nearest_dist or nearest_dist < -0.5:
				nearest_dist = current_dist
				nearest_player = player_character
	
	return nearest_player


# Find the nearest Enemy that is not an ally.
func get_nearest_hostile_enemy() -> Enemy:
	# TODO: Doesn't wokr exactly because it doesn't find a new enemy target when
	# 1. Target dies
	# 2. Target becoems an ally
	# Would need to solve this by making new signals and binding to them.
	var nearest_enemy: Enemy = null
	var nearest_dist: float = -1.0
	var current_dist: float = 0.0
	
	for enemy: Enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_ally:
			current_dist = global_position.distance_squared_to(enemy.global_position)
			if current_dist < nearest_dist or nearest_dist < -0.5:
				nearest_dist = current_dist
				nearest_enemy = enemy
	
	return nearest_enemy


func take_damage(damage: float) -> void:
	var damage_indicator = damage_indicator_scene.instantiate()
	damage_indicator.global_position = global_position
	damage_indicator.text = str(damage)
	get_tree().root.get_node("Playground").add_child(damage_indicator)
	
	health -= snapped(damage, 1)
	$AnimationPlayer.play("take_damage")
	if health <= 0 and is_multiplayer_authority():
		die.rpc_id(1)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is BulletHitbox:
		take_damage(area.damage)
		return
	
	var other = area.get_parent()
	if (not is_ally and 
		other is PlayerCharacterBody2D and 
		multiplayer.get_unique_id() == other.get_multiplayer_authority()
	):
		# Enemy is colliding with a player. Only consider damaging the local player.
		colliding_targets.append(other)
	elif other is Enemy and not other.is_ally:
		# When allied, deal damage to other Enemies.
		colliding_targets.append(other)


func _on_area_2d_area_exited(area: Area2D) -> void:
	# Remove objects from our track of targets when they stop colliding with this Enemy.
	if not is_ally:
		if area.get_collision_layer_value(4):
			var node: Node2D = area.get_parent()
			if node is PlayerCharacterBody2D and node in colliding_targets:
				colliding_targets.remove_at(colliding_targets.find(node))
	else:
		if area.get_collision_layer_value(2):
			var node: Node2D = area.get_parent()
			if node is Enemy and node in colliding_targets:
				colliding_targets.remove_at(colliding_targets.find(node))


# Turn this Enemy into an ally of the player. Will instead try to damage Enemies that 
# are not allies.
@rpc("any_peer", "call_local")
func make_ally(new_lifetime: float, new_damage: float) -> void:
	is_ally = true
	lifetime = new_lifetime
	ally_damage = new_damage
	colliding_targets.clear()
	collider_area.collision_mask = 2
	# We will now treat this Enemy as a player bullet.
	collider_area.collision_layer = 0
	
	# Stop color animation so that we can apply this "ally" color.
	$AnimationPlayer.stop()
	if sprite != null and not sprite.is_queued_for_deletion():
		sprite.self_modulate = Color("00cc7e")
	
	# Since this Enemy essentially died, spawn EXP from it
	if is_multiplayer_authority():
		_spawn_loot()
	
	allied.emit(self)
	_find_new_target()


# Delete this enemy and spawn EXP orbs. Only call on the server.
@rpc("any_peer", "call_local")
func die() -> void:
	if not is_multiplayer_authority():
		return

	if not is_ally:
		_spawn_loot()
	
	died.emit(self)
	queue_free()


# Randomly spawns EXP, gold, or nothing from this Enemy. Call after it dies.
func _spawn_loot() -> void:
	var random_value := randf()
	if random_value <= _threshold_exp:
		var exp_orb = exp_scene.instantiate()
		exp_orb.global_position = global_position
		get_tree().root.get_node("Playground").call_deferred("add_child", exp_orb, true)
	elif random_value <= _threshold_gold:
		var gold := gold_scene.instantiate()
		gold.global_position = global_position
		get_tree().root.get_node("Playground").call_deferred("add_child", gold, true)
	else:
		# Nothing rewarded
		pass
