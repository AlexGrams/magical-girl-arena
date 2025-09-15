extends Bullet


## Time in seconds that this mine's damage collider will be active for before the bullet is destroyed.
@export var _explosion_lifetime: float = 0.05
## Path to explosion VFX.
@export var flower_scene: String = ""

## Saved bullet collision layer for when we reactivate the collision.
var _collision_layer: int = 0
var _collision_mask: int = 0
## True after this mine has detonated.
var _exploded: bool = false
## Only not null on powerup owner client.
var _powerup_mines: PowerupMines = null


func _ready() -> void:
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.MINES_SEEDS, true, lifetime)
	_collision_layer = collider.collision_layer
	_collision_mask = collider.collision_mask
	collider.collision_layer = 0
	collider.collision_mask = 0
	
	ResourceLoader.load_threaded_request(flower_scene, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)


func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	death_timer += delta
	
	if death_timer >= lifetime and not _exploded:
		# The mine just exceeded its lifetime, so blow up. 
		_explode()
	elif death_timer >= lifetime + _explosion_lifetime and is_multiplayer_authority():
		# The mine has exploded and lingered, so remove it.
		queue_free()


## Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, _data: Array) -> void:
	if is_owned_by_player:
		if multiplayer.get_unique_id() == collider.owner_id:
			_powerup_mines = GameState.get_local_player().get_node_or_null("PowerupMines")
	else:
		# Make the bullet hurt players
		_is_owned_by_player = false
		_health = max_health
		_modify_collider_to_harm_players()


## Deal damage in an area around where the bullet is currently.
func _explode() -> void:
	_exploded = true
	
	collider.collision_layer = _collision_layer
	collider.collision_mask = _collision_mask
	
	# Sound effect
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.MINES_EXPLODED)
	# Spawn explosion VFX
	var playground: Node2D = get_tree().root.get_node_or_null("Playground")
	if playground != null:
		var flower_vfx = ResourceLoader.load_threaded_get(flower_scene).instantiate()
		flower_vfx.global_position = global_position
		playground.add_child(flower_vfx)
	
	sprite.hide()


func _on_area_2d_area_entered(area: Area2D) -> void:
	super(area)
	
	if collider.owner_id == multiplayer.get_unique_id() and area.get_parent() is Enemy:
		_powerup_mines.energy_did_damage()
