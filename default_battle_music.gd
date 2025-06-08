extends AudioStreamPlayer

## Music to be looped during map 1
## Will need to make this nicer at some point
@export var map_1_loop_1: AudioStream # Plays for 45 seconds
@export var map_1_loop_2: AudioStream # Plays for 8 min 15 secs
@export var map_1_loop_3: AudioStream # Plays forever until this node is deleted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_map_one_music()

## This is so scuffed.
## AudioManager continues to process during pauses, so it won't be synced
## with the in-game timer.
func play_map_one_music():
	stream = map_1_loop_1
	play()
	await get_tree().create_timer(45).timeout
	stream = map_1_loop_2
	play()
	await get_tree().create_timer(8 * 60 + 15).timeout
	stream = map_1_loop_3
	play()
