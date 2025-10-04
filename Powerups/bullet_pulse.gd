extends Bullet

## Final scale
@export var _final_scale:float = 2.5
## How much the max size increases when this Powerup is level 3.
@export var _level_3_size_multiplier: float = 1.25
## Magnitude of knockback in units/second.
@export var _knockback_speed: float = 500.0
## Time in seconds that knockback is applied.
@export var _knockback_duration: float = 0.25
@export var _notes_ring_sprite: Sprite2D

## Color of sprite
var sprite_color:String = "ffffff"
var _owner: Node2D = null
## Multiplayer ID of the player from which this Pulse originates from.
var _original_character_id: int = 0
## Is this powerup owned by a player level three or higher?
var _is_level_three: bool = false
## Does this powerup apply knockback? Only applies for Pulses centered at the Powerup owner.
var _has_knockback: bool = false
var _crit_chance: float = 0.0
var _crit_multiplier: float = 1.0
var _area_size_boost: bool = false


func _ready() -> void:
	_notes_ring_sprite.rotation_degrees = randi_range(0, 360)
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.set_parallel()
	tween.tween_property(self, "scale", Vector2(_final_scale, _final_scale), lifetime)
	tween.tween_property(sprite, "modulate", Color.html(sprite_color + "00"), lifetime)


func _process(delta: float) -> void:
	global_position = _owner.global_position
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 7
		or typeof(data[0]) != TYPE_NODE_PATH	# Parent node path 
		or typeof(data[1]) != TYPE_INT			# Original player ID
		or typeof(data[2]) != TYPE_INT			# Power level
		or typeof(data[3]) != TYPE_BOOL			# Is level three
		or typeof(data[4]) != TYPE_FLOAT		# Crit chance
		or typeof(data[5]) != TYPE_FLOAT		# Crit multiplier
		or typeof(data[6]) != TYPE_BOOL			# Is boosted by Area Size charm
	):
		push_error("Malformed data array")
		return
	
	# Change color and size based on level
	match data[2]:
		1:
			sprite.modulate = Color.html("ffffff")
		2:
			sprite.modulate = Color.html("fff987")
		3:
			sprite.modulate = Color.html("7bff57")
		4:
			sprite.modulate = Color.html("3dfff5")
		5:
			sprite.modulate = Color.html("e15cff")
	
	_owner = get_tree().root.get_node(data[0])
	_original_character_id = data[1]
	_is_level_three = data[3]
	_crit_chance = data[4]
	_crit_multiplier = data[5]
	if data[6]:
		_area_size_boost = true
		_final_scale *= 1.5
	_is_owned_by_player = is_owned_by_player
	
	# TODO: Stacking scaling
	#_final_scale = _final_scale + (1 * (data[2] - 1))
	if _is_level_three:
		_final_scale *= _level_3_size_multiplier
	
	# Only apply knockback on Pulses originating from the owning player.
	if GameState.player_characters[_original_character_id] == _owner:
		_has_knockback = true
	
	if _original_character_id == multiplayer.get_unique_id():
		var powerup_pulse: PowerupPulse = GameState.get_local_player().get_node_or_null("PowerupPulse")
		if powerup_pulse != null:
			powerup_pulse.add_pulse_this_beat()


## Damaging area for Enemies. Apply knockback to damaged Enemies.
func _on_area_2d_entered(area: Area2D) -> void:
	var other = area.get_parent()
	if other != null and _has_knockback and other is Enemy:
		other.set_knockback((other.global_position - global_position).normalized() * _knockback_speed, _knockback_duration)


## Spread area for allies. Apply a status to allies that causes a Pulse bullet at their location
## on the next Pulse interval.
func _on_spread_area_2d_entered(area: Area2D) -> void:
	var other = area.get_parent()
	
	if (
			other != _owner 
			and other == GameState.get_local_player()
	):
		# Apply StatusPulse to the other character
		var status_pulse: Status = other.get_status("Pulse")
		if status_pulse == null:
			status_pulse = StatusPulse.new()
			status_pulse.set_properties(
				_original_character_id, 
				collider.powerup_index,
				collider.damage, 
				_is_level_three,
				_crit_chance,
				_crit_multiplier,
				_area_size_boost
			)
			other.add_status(status_pulse)
		elif _is_level_three:
			status_pulse.stack()


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass
