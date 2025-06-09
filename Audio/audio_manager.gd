extends Node2D

# AudioManager is used for repetitive sound effects, such as picking up experience or damaging enemies
# Script created based on this video: https://www.youtube.com/watch?v=Egf2jgET3nQ

@export var sound_effect_settings : Array[SoundEffectSettings]
@export var default_main_menu_music: AudioStream

## Instantiate to play default battle music. Need to manually queue_free.
@export var battle_music_player: PackedScene
@export var main_menu_music_player: AudioStreamPlayer
## Music to be looped during map 1
## Will need to make this nicer at some point
@export var map_1_loop_4: AudioStream # Plays during boss
@export var map_1_victory: AudioStream # Plays during victory

var sound_effect_dict : Dictionary

## Value by which to scale the volume of sounds played in the game.
var _volume_multiplier: float = 1.0
## Value by which to scale the volume of MUSIC played in the game.
var _music_volume_multiplier: float = 1.0
## Saved child from when you instantiate the battle_music_player.
var _battle_music_player_node:AudioStreamPlayer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for sfx in sound_effect_settings:
		sound_effect_dict[sfx.type] = sfx


func set_volume_multiplier(value: float) -> void:
	_volume_multiplier = value

func set_music_volume_multiplier(value: float) -> void:
	_music_volume_multiplier = value
	update_music_volume()

## Plays a sound. RPC calls to this should be used sparingly, as there are often ways to 
## replicate sounds without having to do a separate RPC just for the audio.
## For example, if a sound is played when the player shoots, the bullet's _ready function should
## create the sound instead of the shooting player calling this function via RPC.
@rpc("any_peer", "call_local")
func create_audio_at_location(location, sfx_type: SoundEffectSettings.SOUND_EFFECT_TYPE, change_length:bool = false, desired_length:float = -1):
	if sfx_type in sound_effect_dict:
		var sfx:SoundEffectSettings = sound_effect_dict[sfx_type]
		if !sfx.has_reached_limit():
			sfx.update_audio_count(1)
			var new_2D_audio = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			
			new_2D_audio.position = location
			new_2D_audio.stream = sfx.sound_effect
			new_2D_audio.volume_db = linear_to_db(db_to_linear(sfx.volume) * _volume_multiplier)
			if change_length:
				new_2D_audio.pitch_scale = (new_2D_audio.stream.get_length() / desired_length)
			else:
				new_2D_audio.pitch_scale = sfx.pitch_scale
				new_2D_audio.pitch_scale += randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			new_2D_audio.finished.connect(sfx.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			
			new_2D_audio.play()
	else:
		push_warning("SFX type not found: ", sfx_type)


func create_audio(sfx_type: SoundEffectSettings.SOUND_EFFECT_TYPE, play_while_paused: bool = false):
	if sfx_type in sound_effect_dict:
		var sfx:SoundEffectSettings = sound_effect_dict[sfx_type]
		if !sfx.has_reached_limit():
			sfx.update_audio_count(1)
			var new_audio := AudioStreamPlayer.new()
			add_child(new_audio)
			
			new_audio.stream = sfx.sound_effect
			new_audio.volume_db = linear_to_db(db_to_linear(sfx.volume) * _volume_multiplier)
			new_audio.pitch_scale = sfx.pitch_scale
			new_audio.pitch_scale += randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			new_audio.finished.connect(sfx.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			
			if play_while_paused:
				new_audio.process_mode = Node.PROCESS_MODE_ALWAYS
			
			new_audio.play()

func update_music_volume():
	main_menu_music_player.volume_db = linear_to_db(db_to_linear(-20) * _music_volume_multiplier)

func play_main_menu_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	update_music_volume()
	main_menu_music_player.stream = default_main_menu_music
	main_menu_music_player.play()

## This is so scuffed.
## music_player automatically plays music through its own script.
func play_map_one_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	main_menu_music_player.stop()
	var music_player = battle_music_player.instantiate()
	music_player.volume_db = linear_to_db(db_to_linear(-30) * _music_volume_multiplier)
	add_child(music_player)
	_battle_music_player_node = music_player
	print(_battle_music_player_node)

func play_victory_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	
	var new_audio := AudioStreamPlayer.new()
	add_child(new_audio)
	new_audio.stream = map_1_victory
	new_audio.volume_db = linear_to_db(db_to_linear(-10) * _volume_multiplier)
	new_audio.finished.connect(new_audio.queue_free)

func play_boss_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	update_music_volume()
	main_menu_music_player.stream = map_1_loop_4
	main_menu_music_player.play()
