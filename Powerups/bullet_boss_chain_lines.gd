extends Bullet


## How far the bullet is moved to make it spawn and despawn off the map.
const OFF_MAP_DISPLACEMENT: float = 5000.0

## How long it takes the chain to move into its position on the map.
@export var _travel_time: float = 1.0
## Audio play that plays the chain sound effect
@export var _audio_player: AudioStreamPlayer2D

var _travel_timer: float = 0.0
## Displacement per second of the chain while it is moving.
var _velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if lifetime > 0.0:
		if _travel_timer > 0.0:
			# Play chain sound again
			if !_audio_player.playing:
				_audio_player.play()
			# Stage 1: Move into the map
			global_position += _velocity * delta
			_travel_timer -= delta
		else:
			# Stage 2: Wait in place on the map
			lifetime -= delta
			if lifetime <= 0.0:
				_travel_timer = _travel_time
			# Make sure chain sound doesn't play
			if _audio_player.playing:
				_audio_player.stop()
	else:
		# Play chain sound again
		if !_audio_player.playing:
			_audio_player.play()
		# Stage 3: Move off the map
		global_position += _velocity * delta
		_travel_timer -= delta
		if _travel_timer <= 0.0:
			queue_free()


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (len(data) != 0
	):
		push_error("Malformed Bullet setup")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	if not is_owned_by_player:
		_modify_collider_to_harm_players()
		rotation = direction.angle()
		_velocity = direction * OFF_MAP_DISPLACEMENT / _travel_time
		global_position -= direction * OFF_MAP_DISPLACEMENT
		_travel_timer = _travel_time
