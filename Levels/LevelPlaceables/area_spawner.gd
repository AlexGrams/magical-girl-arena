class_name AreaSpawner
extends Node2D
## Spawns objects at a random position within an area.


## True when this spawner is able to make objects automatically.
@export var enabled: bool = true
## The rectangular shape for the area in which enemies will spawn in 
@export var spawn_area: CollisionShape2D = null

# The bounds for spawning in global coordinates.
var _spawn_x_min: float = 0
var _spawn_x_max: float = 0
var _spawn_y_min: float = 0
var _spawn_y_max: float = 0


func _ready() -> void:
	var spawn_rect := spawn_area.get_shape().get_rect()
	_spawn_x_min = global_position.x + spawn_rect.position.x * global_scale.x
	_spawn_x_max = global_position.x + (spawn_rect.position.x + spawn_rect.size.x) * global_scale.x
	_spawn_y_min = global_position.y + spawn_rect.position.y * global_scale.y
	_spawn_y_max = global_position.y + (spawn_rect.position.y + spawn_rect.size.y) * global_scale.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Enable or disable this spawner
func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled


# Toggle this spawner
func toggle_enabled() -> void:
	enabled = !enabled


# Make an object of this spawner's type within its designated spawn area. Spawning is
# done periodically by default, but this function can be called to spawn manually.
func spawn(scene_to_spawn: PackedScene) -> Node2D:
	var obj = scene_to_spawn.instantiate()
	var spawn_pos = Vector2(
		randf_range(_spawn_x_min, _spawn_x_max), 
		randf_range(_spawn_y_min, _spawn_y_max)
	)
	
	get_node("..").add_child(obj, true)
	if obj.has_method("teleport"):
		obj.teleport.rpc(spawn_pos)
	else:
		obj.global_position = spawn_pos
	
	return obj
