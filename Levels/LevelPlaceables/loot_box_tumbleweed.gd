extends LootBox


## Speed in units per second.
@export var _speed: float = 200.0 
@export var _character_body_2d: CharacterBody2D = null
@export var _area: Area2D = null

## True when the Tumbleweed is above an abyss.
var _is_invulnerable: bool = false


func _physics_process(delta: float) -> void:
	super(delta)
	
	_character_body_2d.move_and_slide()
	
	# Hardcoded values to determine when the tumbleweed goes off the map.
	if is_multiplayer_authority() and global_position.x < -2000 or global_position.x > 4000:
		queue_free()


## Move LootBox to a location. Call using RPC for replication.
@rpc("authority", "call_local")
func teleport(pos: Vector2) -> void:
	super(pos)
	
	# Sort of a hack to move in the opposite direction across the arena.
	if global_position.x > 0:
		_character_body_2d.velocity = Vector2.LEFT * _speed
		anim_player.play("rolling_left")
	else:
		_character_body_2d.velocity = Vector2.RIGHT * _speed
		anim_player.play("rolling_right")


func _teleport(pos: Vector2) -> void:
	global_position = pos


func _on_area_2d_entered(area: Area2D) -> void:
	# Don't take damage if we're on top of an abyss right now.
	if area.get_parent() is DesertMapPiece:
		hide()
		_is_invulnerable = true
	
	if _is_invulnerable:
		return
	
	super(area)


func _on_area_2d_exited(area: Area2D) -> void:
	if area.get_parent() is DesertMapPiece:
		# Don't remove invulnerability if still colliding with another map piece.
		for other: Area2D in _area.get_overlapping_areas():
			if other.get_parent() is DesertMapPiece:
				return
		_is_invulnerable = false
		show()
