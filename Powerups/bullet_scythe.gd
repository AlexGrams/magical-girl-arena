extends Bullet

@export var radius = 2
var owning_player: PlayerCharacterBody2D = null


func set_damage(damage: float):
	$BulletOffset/Area2D.damage = damage


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	# TODO: Go back and forth with this one
	global_position = owning_player.global_position
	rotate(speed * delta)
	
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


# Set up other properties for this bullet
func setup_bullet(data: Array) -> void:
	if (
		data.size() != 1
		or typeof(data[0]) != TYPE_INT		# Owning ID
	):
		return
		
	owning_player = GameState.player_characters.get(data[0])
	
	if owning_player == null:
		push_error("Scythe bullet has a null owner. Player ID ", str(data[0]), 
			" was not found in GameState.player_characters.")
		return
	
	$BulletOffset.position.y = radius
