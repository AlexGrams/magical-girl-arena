extends BulletContinuous


## Time in seconds that ally buff this puddle applies stays on the player.
@export var _status_duration: float = 1.0
@export var _colliding_players: Array[PlayerCharacterBody2D] = []


func _process(delta: float) -> void:
	super(delta)
	
	# Reset the duration of StatusPuddle as long as the player is touching this puddle.
	for player: PlayerCharacterBody2D in _colliding_players:
		var status_puddle = player.get_status("Puddle")
		if status_puddle != null:
			status_puddle.duration = _status_duration


## Applies StatusPuddle to allies that overlap if they don't have the status already. Status is only
## spawned on the client that owns the colliding player.
func _on_ally_area_2d_entered(area: Area2D) -> void:
	var player: PlayerCharacterBody2D = area.get_parent()
	if player != null:
		if GameState.get_local_player() == player and player.get_status("Puddle") == null:
			var status_puddle = StatusPuddle.new()
			status_puddle.duration = _status_duration
			player.add_status(status_puddle)
		_colliding_players.append(player)


func _on_ally_area_2d_exited(area: Area2D) -> void:
	var player: PlayerCharacterBody2D = area.get_parent()
	if player != null:
		var index: int = _colliding_players.find(player)
		if index != -1:
			_colliding_players.remove_at(index)
