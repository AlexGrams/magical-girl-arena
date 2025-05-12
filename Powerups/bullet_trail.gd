extends Bullet

## How much damage this bullet does.
var _damage: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


func set_damage(damage: float):
	_damage = damage


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	# Make the bullet hurt players
	if not is_owned_by_player:
		_modify_collider_to_harm_players()
	
	# Disable process and collision signals for non-owners.
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process(false)
		collider.area_entered.disconnect(_on_area_2d_entered)
		collider.area_exited.disconnect(_on_area_2d_exited)


## Apply damage continually to any overlapping Enemies.
func _on_area_2d_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if other != null and other is Enemy:
		other.add_continuous_damage(_damage)


func _on_area_2d_exited(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if other != null and other is Enemy:
		other.add_continuous_damage(-_damage)
