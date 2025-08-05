extends Bullet
## Applies a boost to all turrets in the scene for a duration.


func _ready() -> void:
	pass 


func _process(_delta: float) -> void:
	pass


## Set up other properties for this bullet and boost existing turrets in the scene.
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_FLOAT		# Ultimate duration
	):
		push_error("Malformed data array")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	AudioManager.create_audio_at_location.rpc(global_position, sound_effect)
	get_tree().call_group("bullet_turret", "boost", data[0])
	
	if is_multiplayer_authority():
		queue_free()
