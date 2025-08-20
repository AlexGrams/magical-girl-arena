extends BulletContinuous


## Time in seconds that ally buff this puddle applies stays on the player.
@export var _status_duration: float = 0.5
## Used to apply status to allies when this bullet is stepped on and detonates.
@export var _splash_area: BulletHitbox = null
@export var _puddle_sprite: Sprite2D = null
## Splash explosion effect for when stepping on the puddle
@export var _splash_particles_scene: String = ""

var _splash_area_collision_layer: int = 0
var _splash_area_collision_mask: int = 0
var _exploded_frame_count: int = -1
var _has_level_3_upgrade: bool = false


func set_damage(damage: float, is_crit: bool = false):
	_damage = damage
	# TODO: Might need to separate this later.
	_splash_area.damage = damage * 50.0
	_splash_area.is_crit = is_crit


func _ready() -> void:
	# Animate puddle entering the world
	var full_scale = _puddle_sprite.scale
	_puddle_sprite.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_puddle_sprite, "scale", full_scale, 0.5)
	super()
	
	_splash_area_collision_layer = _splash_area.collision_layer
	_splash_area_collision_mask = _splash_area.collision_mask
	_splash_area.collision_layer = 0
	_splash_area.collision_mask = 0
	
	# Asynchronously load the splash VFX to prevent a lag spike
	ResourceLoader.load_threaded_request(_splash_particles_scene, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)
	
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


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 2
		or typeof(data[0]) != TYPE_FLOAT	# Lifetime
		or typeof(data[1]) != TYPE_BOOL		# Is level 3+ or not
	):
		push_error("Malformed bullet setup data Array for bullet_puddle.gd.")
		return
	
	lifetime = data[0]
	_has_level_3_upgrade = data[1]
	
	# Make the bullet hurt players
	if not is_owned_by_player:
		_modify_collider_to_harm_players()
	
	# Disable process and collision signals for non-owners.
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process(false)


## If a player touches this bullet, make an explosion that damages enemies and buffs allies.
func _on_splash_area_2d_entered(area: Area2D) -> void:
	if _exploded_frame_count <= -1 and area.get_parent() is PlayerCharacterBody2D:
		_exploded_frame_count = 0
		_splash_area.collision_layer = _splash_area_collision_layer
		_splash_area.collision_mask = _splash_area_collision_mask
		
		# Play splash effect
		var splash_explosion = ResourceLoader.load_threaded_get(_splash_particles_scene).instantiate()
		splash_explosion.global_position = global_position
		get_tree().root.add_child(splash_explosion)


## Applies StatusPuddle to allies that overlap if they don't have the status already. Status is only
## spawned on the client that owns the colliding player.
func _on_ally_area_2d_entered(area: Area2D) -> void:
	# This is the level 3 effect.
	if _has_level_3_upgrade:
		var player: Node = area.get_parent()
		if player != null and GameState.get_local_player() == player:
			var status_puddle: Status = player.get_status("Puddle")
			if status_puddle == null:
				status_puddle = StatusPuddle.new()
				status_puddle.duration = _status_duration
				player.add_status(status_puddle)
			else:
				status_puddle.duration = _status_duration


## Set how visible this bullet is using the local client's bullet opacity setting.
func _update_bullet_opacity() -> void:
	pass
