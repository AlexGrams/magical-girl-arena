extends Bullet


## Magnitude of knockback in units/second.
@export var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.25
@export var _notes_ring_sprite: Sprite2D

var _owner: Node2D = null


func _ready() -> void:
	_notes_ring_sprite.rotation_degrees = randi_range(0, 360)


func _process(delta: float) -> void:
	global_position = _owner.global_position
	scale += Vector2(delta * speed, delta * speed)
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_NODE_PATH	# Parent node path 
	):
		push_error("Malformed data array")
		return
	
	_owner = get_tree().root.get_node(data[0])
	_is_owned_by_player = is_owned_by_player


func _on_area_2d_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null and enemy is Enemy:
		enemy.set_knockback((enemy.global_position - global_position).normalized() * _knockback_speed, _knockback_duration)
