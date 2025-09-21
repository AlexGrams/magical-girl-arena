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

## Dictionary of all SFX from sound_effect_settings. Key = SoundEffectSettings.SOUND_EFFECT_TYPE
var sound_effect_dict : Dictionary

## Saved child from when you instantiate the battle_music_player.
var _battle_music_player_node:AudioStreamPlayer = null

## Num of times the enemy hit sound is allowed to play at the same time. Shared between "Enemy hit" and "Enemy hit critical"
@export var _enemy_hit_limit: int = 20
## How many enemy hit sounds are currently playing.
var _enemy_hit_limit_counter: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for sfx in sound_effect_settings:
		sound_effect_dict[sfx.type] = sfx

## Used to update bus volumes from volume sliders in settings screen
func update_bus_volume(linear_volume: float, bus_name: String) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(linear_volume))

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
			new_2D_audio.volume_db = sfx.volume
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

func create_audio(sfx_type: SoundEffectSettings.SOUND_EFFECT_TYPE) -> AudioStreamPlayer:
	if sfx_type in sound_effect_dict:
		var sfx:SoundEffectSettings = sound_effect_dict[sfx_type]
		if sfx.can_be_played():
			sfx.update_audio_count(1)
			var new_audio := AudioStreamPlayer.new()
			add_child(new_audio)
			
			new_audio.bus = sfx.bus
			new_audio.stream = sfx.sound_effect
			new_audio.volume_db = sfx.volume
			new_audio.pitch_scale = sfx.pitch_scale
			new_audio.pitch_scale += randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			new_audio.finished.connect(sfx.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			
			if sfx.play_while_paused:
				new_audio.process_mode = Node.PROCESS_MODE_ALWAYS
			
			new_audio.play()
			return new_audio
	return null

func play_main_menu_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()

	main_menu_music_player.stream = default_main_menu_music
	main_menu_music_player.play()

## This is so scuffed.
## music_player automatically plays music through its own script.
func play_map_one_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	# Stop main menu music
	main_menu_music_player.stop()
	# Add new battle music player, which will play tracks 1-3
	var music_player = battle_music_player.instantiate()
	music_player.bus = "Music"

	add_child(music_player)
	_battle_music_player_node = music_player

## Plays victory sound, meant to be called when players win
func play_victory_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	
	# Add new music player for victory music
	var new_audio := AudioStreamPlayer.new()
	new_audio.bus = "Music"
	add_child(new_audio)
	new_audio.stream = map_1_victory
	new_audio.finished.connect(new_audio.queue_free)

## Plays boss music, meant to be played after constellation is summoned
func play_boss_music():
	# Remove battle music if playing
	if _battle_music_player_node != null:
		_battle_music_player_node.queue_free()
	main_menu_music_player.stream = map_1_loop_4
	main_menu_music_player.play()

## Pauses any battle music in play. May also pause main menu music.
func pause_music():
	if _battle_music_player_node != null:
		_battle_music_player_node.stream_paused = true
	main_menu_music_player.stream_paused = true

func play_enemy_hit(is_crit:bool = false, sfx_type:SoundEffectSettings.SOUND_EFFECT_TYPE = SoundEffectSettings.SOUND_EFFECT_TYPE.ON_ENEMY_HIT):
	if _enemy_hit_limit_counter < _enemy_hit_limit:
		var new_audio = create_audio(sfx_type)
		if new_audio != null:
			_enemy_hit_limit_counter += 1
			# Prioritize volume
			var pitch_scale = new_audio.pitch_scale
			if is_crit:
				pitch_scale = new_audio.pitch_scale + 0.06
				
			new_audio.pitch_scale = pitch_scale
			new_audio.finished.connect(
				func():
					_enemy_hit_limit_counter -= 1
			)
