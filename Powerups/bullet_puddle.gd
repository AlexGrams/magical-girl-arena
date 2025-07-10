extends BulletContinuous


## Time in seconds that ally buff this puddle applies stays on the player.
@export var _status_duration: float = 1.0
## Used to apply status to allies when this bullet is stepped on and detonates.
@export var _splash_area: BulletHitbox = null

var _splash_area_collision_layer: int = 0
var _splash_area_collision_mask: int = 0
var _exploded_frame_count: int = -1


func set_damage(damage: float):
	_damage = damage
	# TODO: Might need to separate this later.
	_splash_area.damage = damage * 50.0


func _ready() -> void:
	super()
	
	_splash_area_collision_layer = _splash_area.collision_layer
	_splash_area_collision_mask = _splash_area.collision_mask
	_splash_area.collision_layer = 0
	_splash_area.collision_mask = 0
	
	if not is_multiplayer_authority():
		set_physics_process(false)


func _process(delta: float) -> void:
	super(delta)


func _physics_process(_delta: float) -> void:
	if _exploded_frame_count >= 0:
		_exploded_frame_count += 1
		if _exploded_frame_count >= 2:
			queue_free()


## Initialize properties used by the bullet for analytics on how much damage each of the player's powerups has done.
func setup_analytics(owner_id: int, powerup_index: int) -> void:
	_owner_id = owner_id
	_powerup_index = powerup_index
	_splash_area.owner_id = owner_id
	_splash_area.powerup_index = powerup_index


## If a player touches this bullet, make an explosion that damages enemies and buffs allies.
func _on_splash_area_2d_entered(area: Area2D) -> void:
	if _exploded_frame_count <= -1 and area.get_parent() is PlayerCharacterBody2D:
		_exploded_frame_count = 0
		_splash_area.collision_layer = _splash_area_collision_layer
		_splash_area.collision_mask = _splash_area_collision_mask


## Applies StatusPuddle to allies that overlap if they don't have the status already. Status is only
## spawned on the client that owns the colliding player.
func _on_ally_area_2d_entered(area: Area2D) -> void:
	var player: Node = area.get_parent()
	if player != null and GameState.get_local_player() == player:
		var status_puddle: Status = player.get_status("Puddle")
		if status_puddle == null:
			status_puddle = StatusPuddle.new()
			status_puddle.duration = _status_duration
			player.add_status(status_puddle)
		else:
			status_puddle.duration = _status_duration
