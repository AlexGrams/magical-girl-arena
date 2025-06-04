extends Bullet


## Time in seconds that this mine's damage collider will be active for before the bullet is destroyed.
@export var _explosion_lifetime: float = 0.05
@export var flower_scene: PackedScene

## Saved bullet collision layer for when we reactivate the collision.
var _collision_layer: int = 0
## True after this mine has detonated.
var _exploded: bool = false


func _ready() -> void:
	_collision_layer = collider.collision_layer
	collider.collision_layer = 0


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


## Deal damage in an area around where the bullet is currently.
func _explode() -> void:
	_exploded = true
	
	collider.collision_layer = _collision_layer
	
	# Spawn explosion VFX
	var playground: Node2D = get_tree().root.get_node_or_null("Playground")
	if playground != null:
		var flower_vfx = flower_scene.instantiate()
		flower_vfx.global_position = global_position
		playground.add_child(flower_vfx)
	
	sprite.hide()
