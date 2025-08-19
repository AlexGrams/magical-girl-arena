extends Ability
## Click areas on the screen to bring down large bombs that deal massive damage. 

@export var _damage_curve: Curve = preload("res://Curves/Abilities/ability_ult_vale.tres")

## Number of bombs the player can drop using this ability.
@export var num_bombs: int = 3
## Time in seconds before each bomb explodes after the player clicks on the screen to place it.
@export var bomb_lifetime: float = 0.5
## Time in seconds that the play has after using this ult to drop bombs. Nothing happens if the player does not
## drop all bombs by the time this ultimate expires.
@export var active_time: float = 10.0
@export var bullet_scene_path := ""

var _mouse_cursor = load("res://Sprites/UI/ArrowSmall.png")
var _target_cursor = load("res://Sprites/UI/Target.png")
## How much damage each bomb does
var _damage: float = 100.0
## How long the player has left to use this ultimate.
var _current_active_time: float = 0.0
var _bombs_remaining: int = 0
var _bullet_spawner: BulletSpawner = null


func _ready() -> void:
	super()
	
	_bullet_spawner = get_tree().root.get_node("Playground/BulletSpawner")


func _process(delta: float) -> void:
	super(delta)
	
	if _current_active_time > 0.0:
		_current_active_time -= delta
		if _current_active_time <= 0.0:
			## Disable ult
			Input.set_custom_mouse_cursor(_mouse_cursor)


func activate() -> void:
	super()
	Input.set_custom_mouse_cursor(_target_cursor)
	_current_active_time = active_time
	_bombs_remaining = num_bombs


func _input(event: InputEvent) -> void:
	# Do nothing if the ult is inactive
	if _current_active_time <= 0.0:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Create bullet
			_bullet_spawner.request_spawn_bullet.rpc_id(
			1, [bullet_scene_path, 
				get_global_mouse_position(), 
				Vector2.ZERO, 
				_damage * (1.0 if randf() > _crit_chance else 2.0), 
				false,
				true,
				-1,
				-1,
				[
					NodePath(""),
					bomb_lifetime
				]
			])
			
			# Count remaining bombs
			_bombs_remaining -= 1
			if _bombs_remaining <= 0:
				_current_active_time = 0.0
				Input.set_custom_mouse_cursor(_mouse_cursor)


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	_damage = _damage_curve.sample(float(_level) / GameState.MAX_LEVEL)
