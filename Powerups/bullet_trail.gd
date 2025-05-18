extends Bullet

## How much damage this bullet does.
var _damage: float = 0.0
## The multiplayer ID of the player that owns this bullet, if any. -1 if player does not. Used for analytics.
var _owner_id: int = -1
## The index of the powerup that created this bullet if it is owned by the player. -1 if it wasn't created
## by a player's powerup. Used for analytics.
var _powerup_index: int = -1


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


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	_owner_id = owner_id
	_powerup_index = powerup_index


## Apply damage continually to any overlapping Enemies.
func _on_area_2d_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if other != null and other is Enemy:
		if is_multiplayer_authority():
			other.add_continuous_damage(_damage)
		if multiplayer.get_unique_id() == _owner_id:
			other.continuous_damage_analytics(_damage, _powerup_index)


func _on_area_2d_exited(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if other != null and other is Enemy:
		other.add_continuous_damage(-_damage)
	if multiplayer.get_unique_id() == _owner_id:
		other.continuous_damage_analytics(_damage, _powerup_index)
