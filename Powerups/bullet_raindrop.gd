extends Bullet


## The highest speed at which hit enemies can be brought towards the bullet's center.
@export var _max_suck_in_speed: float = 400.0
## Particles to spawn when damage activates.
@export var _vfx_path: String = ""

@onready var _max_sqaured_suck_in_speed: float = _max_suck_in_speed * _max_suck_in_speed
var _max_scale: Vector2 = Vector2.ONE
## Collision layer this bullet will use to damage targets.
var _collision_layer: int = 0
## The global position that this bubble will explode at.
var _final_position: Vector2 = Vector2.ZERO
## True for the one frame for which the bullet's collider is active.
var _is_collision_active = false


func _ready() -> void:
	_max_scale = scale
	scale = Vector2.ZERO
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_GROW, true, lifetime)


func _process(delta: float) -> void:
	death_timer += delta
	if death_timer < lifetime:
		# Grow and move
		global_position += direction * speed * delta
		scale = (death_timer / lifetime) * _max_scale


func _physics_process(_delta: float) -> void:
	if death_timer >= lifetime:
		# Bubble pops. Turn the hitbox on for one frame, then delete it.
		if not _is_collision_active:
			_is_collision_active = true
			collider.collision_layer = _collision_layer
			
			# Play bubble SFX
			AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.RAINDROP_POP)
			
			# Make particles
			var playground: Node2D = get_tree().root.get_node_or_null("Playground")
			if playground != null:
				var vfx: GPUParticles2D = load(_vfx_path).instantiate()
				vfx.global_position = global_position
				playground.add_child(vfx)
		elif is_multiplayer_authority():
			queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (
		data.size() != 0
	):
		push_error("Malformed bullet setup data Array.")
		return
	
	_is_owned_by_player = is_owned_by_player
	
	_final_position = global_position + direction * speed * lifetime


## Suck in Enemies that it touches by knocking them towards the bubble's final position.
func _on_area_2d_entered(area: Area2D) -> void:
	var node: Node2D = area.get_parent()
	if node != null and node is Enemy:
		# Limit the speed at which enemies are pulled in. 
		var knockback: Vector2 = (_final_position - node.global_position) / (lifetime - death_timer)
		if knockback.length_squared() >= _max_sqaured_suck_in_speed:
			knockback = knockback.normalized() * _max_suck_in_speed
		
		node.set_knockback(
			knockback, 
			lifetime - death_timer
		)
