extends Bullet


## Bullet collision area.
@export var _area: Area2D = null
## Contains the visuals and collision for the bullet.
@export var _lightning: Node2D = null
## Bullet for lightning arcs.
@export var _lighting_arc_scene: String = ""

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
		data.size() != 1
		or (typeof(data[0])) != TYPE_NODE_PATH	# Target endpoint
	):
		push_error("Malformed data array")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	var rotation_direction: Vector2 = get_node(data[0]).global_position - global_position
	global_position += rotation_direction / 2
	rotation = rotation_direction.angle()
	var length_of_lightning = _area.get_child(0).shape.size.x
	_lightning.scale.x = rotation_direction.length() / length_of_lightning


## Collision only processed on server instance.
func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	
	if enemy != null and enemy is Enemy:
		get_tree().root.get_node("Playground/BulletSpawner").call_deferred("request_spawn_bullet",
			[
				_lighting_arc_scene, 
				enemy.global_position, 
				Vector2.UP, 
				collider.damage, 
				_is_owned_by_player,
				multiplayer.get_unique_id(),
				collider.powerup_index,
				[enemy.get_path(), 3]
			]
		)
