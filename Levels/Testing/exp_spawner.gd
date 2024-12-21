extends Node2D

# EXP orbs spawned per second
@export var active := true
@export var spawn_rate := 100.0
@export var exp_orb_scene_path: String
var exp_orb_scene: Resource
var spawn_interval: float
var spawn_timer := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	exp_orb_scene = load(exp_orb_scene_path)
	spawn_interval = 1.0 / spawn_rate


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not active or not is_multiplayer_authority():
		return
	
	spawn_timer += delta
	if spawn_timer > spawn_interval:
		var exp_orb = exp_orb_scene.instantiate()
		exp_orb.global_position = global_position
		$"..".call_deferred("add_child", exp_orb, true)
		spawn_timer = 0.0
