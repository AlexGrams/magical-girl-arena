extends Bullet


## Bullet collision area.
@export var _area: Area2D = null
## Contains the visuals and collision for the bullet.
@export var _lightning: Node2D = null

var _is_level_three: bool = false
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
## True after the one frame that this bullet lasts for.
var _processed: bool = false
var _freed_area: bool = false


func _ready() -> void:
	if not is_multiplayer_authority():
		_area.area_entered.disconnect(_on_area_2d_entered)
	
	# Play fading out animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(sprite, "modulate", Color.html("ffffff00"), 0.5)


func _process(_delta: float) -> void:
	# This is intentionally blank. It overrides Bullet's _process() function.
	pass


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not _processed:
		_processed = true
		sprite.flip_h = true
	elif not _freed_area:
		# Only delete the collision, but let the lightning fade out
		_freed_area = true
		_area.queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 4
		or typeof(data[0]) != TYPE_NODE_PATH	# Target endpoint
		or typeof(data[1]) != TYPE_BOOL			# Has level 3 upgrade or not
		or typeof(data[2]) != TYPE_FLOAT		# Crit chance
		or typeof(data[3]) != TYPE_FLOAT		# Crit multiplier
	):
		push_error("Malformed data array")
		return
	
	# Level 3 upgrade
	_is_level_three = data[1]
	if data[1]:
		scale.y = scale.y * 2
	
	_crit_chance = data[2]
	_crit_multiplier = data[3]
	
	_is_owned_by_player = is_owned_by_player
	
	var rotation_direction: Vector2 = get_node(data[0]).global_position - global_position
	global_position += rotation_direction / 2
	rotation = rotation_direction.angle()
	var length_of_lightning = _area.get_child(0).shape.size.x
	_lightning.scale.x = rotation_direction.length() / length_of_lightning


## Collision only processed on server instance.
func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	var crit: bool = randf() < _crit_chance
	var total_damage: float = collider.damage* (1.0 if not crit else _crit_multiplier)
	
	if enemy != null and enemy is Enemy:
		GameState.playground.create_lightning_arc.rpc(
			enemy.global_position, 
			total_damage, 
			crit,
			_is_owned_by_player,
			collider.owner_id,
			collider.powerup_index,
			[
				3, 
				_is_level_three, 
				-1.0, 
				enemy.get_path(),
				_crit_chance,
				_crit_multiplier
			]
		)


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass
