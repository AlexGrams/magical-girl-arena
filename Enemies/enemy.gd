class_name Enemy
extends CharacterBody2D

## Base health is the starting health before the curve multiplier is added
@export var base_health: int = 0
## Describes how this enemy's health changes as the game time progresses.
@export var curve_max_health: Curve = preload("res://Curves/Enemies/atom_enemy_max_health.tres")
## Movement speed of this Enemy
@export var speed: float = 100
## Time in seconds between when this Enemy can attack
@export var attack_interval: float = 1.0
@export var attack_damage: float = 10.0
## Time in seconds between checks to see if there is a closer player to target.
@export var retarget_check_interval: float = 5.0
## Parent of this Enemy's collider
@export var collider_area: Area2D = null
@export var sprite: Node2D = null
@export var sound_effect_type: SoundEffectSettings.SOUND_EFFECT_TYPE = SoundEffectSettings.SOUND_EFFECT_TYPE.ON_ENEMY_HIT

@onready var exp_scene = preload("res://Pickups/exp_orb.tscn")
@onready var gold_scene = preload("res://Pickups/gold.tscn")

# Max health is set based off of the current time when this enemy spawns.
var max_health: int = 0
## Current health. Only the server keeps track of Enemy health.
var health: int = 0
# The character that this Enemy is trying to attack.
var target: Node2D = null
# All Objects that this Enemy can damage that it is touching right now.
var colliding_targets: Array[Node2D] = []
# True if it tries to harm Enemies instead of players.
var is_ally := false
# How long this Enemy lasts as an ally before being destroyed
var lifetime: float = 0.0
# Damage this Enemy does to other Enemies when it is an ally.
var ally_damage: float = 0.0

## Playground world that this Enemy was spawned into.
var _playground: Playground = null
## All Powerup objects currently spawned in and added to this Enemy.
var _powerups: Array[Powerup] = []
## How long until this Enemy can attack again
var _attack_timer: float = 0.0
## Time in seconds until this Enemy checks to see if there is a player to target that is closer than its
## current targer.
var _retarget_timer: float = 0.0
## Damage that will be applied to this Enemy every physics frame. Useful for continuous sources of 
## damage such as AOE hazards or damaging debuffs.
var _continuous_damage: float = 0.0
## The sound produced when taking continuous damage. Set by the latest new source of continuous damage.
var _continuous_damage_sfx: SoundEffectSettings.SOUND_EFFECT_TYPE
## For analytics. Key: Powerup index. Value: continuous damage from that powerup.
var _continuous_damage_analytic_data: Dictionary = {}
## Direction and magnitude of knockback.
var _knockback: Vector2 = Vector2.ZERO
## Current remaining knockback duration. 
var _knockback_duration: float = 0.0
## True if this Enemy doesn't take damage when attacked.
var _is_invulnerable: bool = false
## Status to make this Enemy an ally when it dies.
var _status_goth_ult: bool = false
## Properties to apply to this Enemy if it is converted to an ally by Goth's ult status.
var _goth_ult_allied_lifetime: float = 0.0
var _goth_ult_allied_damage: float = 0.0
## How long this Enemy is affected by the Slow status. Slow is not additive, and only one type of slow is applied at a time.
var _status_slow_duration: float = 0.0
## 0 = character moves at full speed, 1 = character doesn't move at all.
var _status_slow_percent: float = 0.0
var _hud_canvas_layer: HUDCanvasLayer = null

# Emitted when this Enemy dies.
signal died(enemy: Enemy)
# Emitted when this Enemy is converted to an ally.
signal allied(enemy: Enemy)


func set_knockback(vector: Vector2, duration: float) -> void:
	_knockback = vector
	_knockback_duration = duration


func set_is_invulnerable(value: bool) -> void:
	_is_invulnerable = value


func _ready() -> void:
	max_health = snapped(base_health * curve_max_health.sample(GameState.get_game_progress_as_fraction()), 1)
	health = max_health
	_retarget_timer = retarget_check_interval
	
	_playground = get_tree().root.get_node("Playground")


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
	
	# Update slow
	if _status_slow_duration > 0.0:
		_status_slow_duration -= delta
		if _status_slow_duration <= 0.0:
			_status_slow_percent = 0.0
	
	if is_multiplayer_authority():
		# Retargeting check: Occasionally see if we should attack a player that is closer than our
		# current target.
		if not is_ally:
			_retarget_timer -= delta
			if _retarget_timer <= 0.0:
				_find_new_target()
				_retarget_timer = retarget_check_interval
		
		# Update allied lifetime
		if is_ally:
			lifetime -= delta
			if lifetime <= 0.0:
				take_damage(health)


func _physics_process(delta: float) -> void:
	# Movement:
	if _knockback_duration >= 0.0:
		# Knockback movement: go in direction of knockback
		velocity = _knockback
		_knockback_duration -= delta
	elif target != null:
		# Normal movement: go towards target.
		velocity = (target.global_position - global_position).normalized() * speed * (1.0 - _status_slow_percent)
	elif is_multiplayer_authority():
		# Invalid target. Try to find a new one.
		_find_new_target()
	move_and_slide()
	
	# Continuous damage 
	if is_multiplayer_authority() and _continuous_damage > 0.0:
		_take_damage(_continuous_damage)
	
	# Record continuous damage from the local player and play damage sound.
	if not _continuous_damage_analytic_data.is_empty():
		AudioManager.play_enemy_hit(false, _continuous_damage_sfx, global_position)
		for index: int in _continuous_damage_analytic_data:
			Analytics.add_powerup_damage(_continuous_damage_analytic_data[index], index)


## Move this enemy to a location.
@rpc("authority", "call_local")
func teleport(pos: Vector2) -> void:
	global_position = pos


# Spawn in and add a Powerup to this Enemy. The Powerup may need extra functionality to 
# account for it not being on the Player. Only call on the server.
func _add_powerup(powerup_scene: PackedScene, activate_on_spawn: bool = true) -> void:
	if not multiplayer.is_server():
		return
	
	var powerup: Powerup = powerup_scene.instantiate()
	powerup.set_authority(get_multiplayer_authority())
	add_child(powerup)
	if activate_on_spawn:
		powerup.activate_powerup_for_enemy()
	_powerups.append(powerup)


## Sets target to the nearest character.
## Makes sure to find a new target if the current one dies.
func _find_new_target() -> void:
	if not is_ally:
		var new_target: Node2D = get_nearest_player_character()
		
		if new_target != null:
			set_target.rpc(new_target.get_path())
			teleport.rpc(global_position)
			if target != null:
				target.died.connect(func():
					target = null
				)
		else:
			# Could not find a new target player, so do nothing probably.
			pass
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


## Sets this Enemy's target using the target node's path within the tree.
## Call via RPC to set this Enemy's target on all clients.
@rpc("authority", "call_local")
func set_target(target_path: NodePath) -> void:
	target = get_node(target_path)


## Changes the amount of damage being done to this Enemy each physics frame. Useful for sources of 
## periodic damage such as AOE damage volumes and debuffs.
func add_continuous_damage(damage: float) -> void:
	AudioManager.play_enemy_hit()
	_continuous_damage = max(_continuous_damage + damage, 0)


## Set how much continuous damage the local client is doing to this Enemy. Allows recording analytic
## data and playing a sound for continuous damage.
func add_local_continuous_damage(damage: float, powerup_index: int, damage_sound: SoundEffectSettings.SOUND_EFFECT_TYPE = SoundEffectSettings.SOUND_EFFECT_TYPE.NONE) -> void:
	if damage > 0:
		_continuous_damage_sfx = damage_sound
	
	if _continuous_damage_analytic_data.has(powerup_index):
		_continuous_damage_analytic_data[powerup_index] = max(round(_continuous_damage_analytic_data[powerup_index] + damage), 0)
	else:
		_continuous_damage_analytic_data[powerup_index] = damage
	
	if _continuous_damage_analytic_data[powerup_index] <= 0.0:
		_continuous_damage_analytic_data.erase(powerup_index)


## Wrapper function for RPC modification without making changes everywhere.
func take_damage(damage: float, hitbox: BulletHitbox = null) -> void:
	# Play hit sound only on the client that caused the damage.
	if hitbox != null and hitbox.owner_id == multiplayer.get_unique_id():
		AudioManager.play_enemy_hit(hitbox.is_crit, hitbox.sound_effect, global_position)
	
	# Do damage only on the server.
	if is_multiplayer_authority():
		var is_crit: bool = hitbox != null and hitbox.is_crit
		_take_damage(damage, is_crit)


## Deals damage to this Enemy. Call via RPC to have effects replicated on all clients.
## Only call on the server
@rpc("any_peer", "call_local")
func _take_damage(damage: float, is_crit: bool = false) -> void:
	if not is_multiplayer_authority() or health <= 0:
		return
	
	# Don't take damage if invulnerable.
	if _is_invulnerable:
		return
	
	health -= snapped(damage, 1)
	
	_playground.create_damage_indicator.rpc(global_position, damage, is_crit)
	if sprite != null and sprite.has_method("take_damage"):
		sprite.take_damage()
	
	if health <= 0:
		die()


## Updates the displayed value on the boss HP bar and the recorded value for analytics.
@rpc("authority", "call_local")
func _update_boss_health_bar(new_percent: float, is_boss: bool) -> void:
	_hud_canvas_layer.update_boss_health_bar(new_percent)
	if is_boss:
		Analytics.set_boss_hp_percent(int(new_percent * 100.0))
	else:
		Analytics.set_miniboss_hp_percent(int(new_percent * 100.0))


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is BulletHitbox:
		take_damage(area.damage, area)
		
		# Analytics: Record damage done by touching a bullet for this client only.
		if area.owner_id == multiplayer.get_unique_id():
			Analytics.add_powerup_damage(area.damage, area.powerup_index)
		
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


## Forces this Enemy to attack a specific target for a set duration.
@rpc("authority", "call_local")
func apply_status_taunted(duration: float, temp_target_path: NodePath) -> void:
	target = get_tree().root.get_node(temp_target_path)
	await get_tree().create_timer(duration).timeout
	target = null


## Apply Goth's Ultimate ability status to this Enemy for a duration
func apply_status_goth_ult(duration: float, ally_lifetime: float, allied_damage: float) -> void:
	_status_goth_ult = true
	_goth_ult_allied_lifetime = ally_lifetime
	_goth_ult_allied_damage = allied_damage
	await get_tree().create_timer(duration).timeout
	_status_goth_ult = false


## Apply a slow to this Enemy. Only the latest slow is applied, and only one slow can be applied at a time.
@rpc("authority", "call_local")
func apply_status_slow(duration: float, percent: float) -> void:
	_status_slow_duration = duration
	_status_slow_percent = percent


# Turn this Enemy into an ally of the player. Will instead try to damage Enemies that 
# are not allies.
@rpc("any_peer", "call_local")
func make_ally(new_lifetime: float, new_damage: float) -> void:
	is_ally = true
	lifetime = new_lifetime
	ally_damage = new_damage
	# Give the ally some health so that we can damage it to destroy it when its lifetime expires.
	health = 1
	
	colliding_targets.clear()
	collider_area.collision_mask = 2
	# We will now treat this Enemy as a player bullet.
	collider_area.collision_layer = 0
	
	# Stop color animation so that we can apply this "ally" color.
	$AnimationPlayer.stop()
	if sprite != null and not sprite.is_queued_for_deletion():
		sprite.change_color(Constants.EnemySpriteType.GOTH_ALLY)
	
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
	if _status_goth_ult:
		# Special case where this Enemy dies while affected by Goth's ult status.
		make_ally.rpc(_goth_ult_allied_lifetime, _goth_ult_allied_damage)
		return
	
	died.emit(self)
	queue_free()


# Randomly spawns EXP, gold, or nothing from this Enemy. Call after it dies.
func _spawn_loot() -> void:
	# Random loot calculation
	var total := _playground.drop_weight_exp + _playground.drop_weight_gold + _playground.drop_weight_nothing
	var _threshold_exp = _playground.drop_weight_exp / total
	var _threshold_gold = _playground.drop_weight_gold / total + _threshold_exp
	
	var random_value := randf()
	if random_value <= _threshold_exp:
		var exp_orb: EXPOrb = exp_scene.instantiate()
		exp_orb.global_position = global_position
		exp_orb.tree_entered.connect(
			func(): exp_orb.teleport.rpc(global_position)
			, CONNECT_DEFERRED
		)
		_playground.call_deferred("add_child", exp_orb, true)
	elif random_value <= _threshold_gold:
		var gold := gold_scene.instantiate()
		gold.global_position = global_position
		gold.tree_entered.connect(
			func(): gold.teleport.rpc(global_position)
			, CONNECT_DEFERRED
		)
		_playground.call_deferred("add_child", gold, true)
	else:
		# Nothing rewarded
		pass
