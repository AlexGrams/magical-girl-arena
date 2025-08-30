class_name EnemyCorrupted
extends EnemyRanged
## A corrupted magical girl enemy. Can use powerups and abilities like the player.

## How long this corrupted enemy stays in the game before leaving. Doesn't drop loot if time runs out.
@export var corrupted_lifetime: float = 0.0
## How much EXP is spawned when defeated.
@export var exp_reward: int = 200
## How much gold is spawned when defeated.
@export var gold_reward: int = 100
## Scene for the Powerup to give to this enemy when it spawns.
@export var default_powerup_path: String = ""

@export var _character: Constants.Character

# How much time this corrupted enemy has left in the game.
var current_lifetime: float = 0.0


func _ready() -> void:
	super()
	
	sprite.set_character(_character, true)
	
	current_lifetime = corrupted_lifetime
	
	_hud_canvas_layer = get_tree().root.get_node("Playground/CanvasLayer")
	_hud_canvas_layer.show_boss_health_bar(float(health) / max_health)
	
	if is_multiplayer_authority():
		# Start dialogue
		var dialogue_play_conditions: Array[Constants.DialoguePlayCondition] = [
			Constants.DialoguePlayCondition.MINIBOSS_SPAWN,
			GameState.playground.get_map_dialogue_condition()
		]
		match _character:
			Constants.Character.GOTH:
				dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_GOTH)
			Constants.Character.SWEET:
				dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_SWEET)
			Constants.Character.VALE:
				dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_VALE)
			Constants.Character.DOVE:
				dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_DOVE)
			_:
				push_error("Play miniboss dialogue not implemented for this character")
		_hud_canvas_layer.start_dialogue(dialogue_play_conditions)
		
		var default_powerup: PowerupData = load(default_powerup_path)
		if default_powerup != null:
			_add_powerup(default_powerup.scene)


func _process(delta: float) -> void:
	super(delta)
	
	current_lifetime -= delta
	if current_lifetime <= 0.0 and is_multiplayer_authority():
		_leave()


func _physics_process(delta: float) -> void:
	super(delta)


func shoot() -> void:
	pass


## Only call on the server. Deals damage to this corrupted enemy. Update health bars on all clients.
@rpc("any_peer", "call_local")
func _take_damage(damage: float, is_crit: bool = false) -> void:
	super(damage, is_crit)
	
	_update_boss_health_bar.rpc(float(health) / max_health, false)


## Does nothing since corrupted Enemies cannot be made into allies.
func make_ally(_new_lifetime: float, _new_damage: float) -> void:
	die()


## Delete the corrupted enemy. Only call on the server.
@rpc("any_peer", "call_local")
func die() -> void:
	if not is_multiplayer_authority():
		return
	
	super()
	
	# Start defeated dialogue
	var dialogue_play_conditions: Array[Constants.DialoguePlayCondition] = [
		Constants.DialoguePlayCondition.MINIBOSS_DEFEATED,
		GameState.playground.get_map_dialogue_condition()
	]
	match _character:
		Constants.Character.GOTH:
			dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_GOTH)
		Constants.Character.SWEET:
			dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_SWEET)
		Constants.Character.VALE:
			dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_VALE)
		Constants.Character.DOVE:
			dialogue_play_conditions.append(Constants.DialoguePlayCondition.MINIBOSS_DOVE)
		_:
			push_error("Play miniboss dialogue not implemented for this character")
	_hud_canvas_layer.start_dialogue(dialogue_play_conditions)
	
	_hud_canvas_layer.hide_boss_health_bar.rpc()


# Despawn the corrupted enemy. Different from dying as it doesn't drop loot.
@rpc("any_peer", "call_local")
func _leave() -> void:
	if not is_multiplayer_authority():
		return
	
	_hud_canvas_layer.hide_boss_health_bar.rpc()
	queue_free()


## Makes a bunch of experience and gives everyone a free powerup of their choice.
func _spawn_loot() -> void:
	GameState.playground.spawn_corrupted_enemy_loot(global_position, exp_reward, gold_reward)
	GameState.corrupted_enemy_defeated.rpc()
