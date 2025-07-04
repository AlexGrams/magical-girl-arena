extends BulletContinuous


## Time in seconds that ally buff this puddle applies stays on the player.
@export var _status_duration: float = 1.0


func _process(delta: float) -> void:
	super(delta)


## Applies StatusPuddle to allies that overlap if they don't have the status already.
func _on_ally_area_2d_entered(area: Area2D) -> void:
	var player: PlayerCharacterBody2D = area.get_parent()
	if player != null:
		var status_puddle = StatusPuddle.new()
		status_puddle.duration = _status_duration
		player.add_status(status_puddle)
