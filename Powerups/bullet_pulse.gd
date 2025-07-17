extends Bullet


## Magnitude of knockback in units/second.
@export var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.25
@export var _notes_ring_sprite: Sprite2D

var _owner: Node2D = null
## Multiplayer ID of the player from which this Pulse originates from.
var _original_character_id: int = 0
var _has_knockback: bool = false


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
		data.size() != 4
		or typeof(data[0]) != TYPE_NODE_PATH	# Parent node path 
		or typeof(data[1]) != TYPE_INT			# Original player ID
		or typeof(data[2]) != TYPE_INT			# Power level
		or typeof(data[3]) != TYPE_BOOL			# Has knockback
	):
		push_error("Malformed data array")
		return
	
	_owner = get_tree().root.get_node(data[0])
	_original_character_id = data[1]
	speed *= 1.0 + 0.5 * (data[2] - 1)
	_has_knockback = data[3]
	_is_owned_by_player = is_owned_by_player


func _on_area_2d_entered(area: Area2D) -> void:
	var other = area.get_parent()
	if other != null:
		if other is Enemy and _has_knockback:
			other.set_knockback((other.global_position - global_position).normalized() * _knockback_speed, _knockback_duration)
		elif other is PlayerCharacterBody2D and other != _owner and other == GameState.get_local_player():
			# Apply StatusPulse to the other character
			var status_pulse: Status = other.get_status("Pulse")
			if status_pulse == null:
				status_pulse = StatusPulse.new()
				status_pulse.set_properties(_original_character_id, collider.damage, _has_knockback)
				other.add_status(status_pulse)
			else:
				status_pulse.stack()
