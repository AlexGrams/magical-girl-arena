extends Node2D

# AudioManager is used for repetitive sound effects, such as picking up experience or damaging enemies
# Script created based on this video: https://www.youtube.com/watch?v=Egf2jgET3nQ

## The max distance from the local player that a hit SFX will be produced. Hits farther
## than this distance don't cause a sound.
const MAX_SQUARED_ENEMY_HIT_DISTANCE: float = 1000 ** 2

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
## If true, all enemy hit SFX will be the same sound instead of being different depending on the bullet.
var _use_same_enemy_hit_sfx: bool = false
## The client's instantiated player character.
var _local_player: Node2D = null

## Num of times the enemy hit sound is allowed to play at the same time. Shared between "Enemy hit" and "Enemy hit critical"
@export var _enemy_hit_limit: int = 20
## How many enemy hit sounds are currently playing.
var _enemy_hit_limit_counter: int = 0
## Used to convert from semitones to pitch scale
const LOG_SEMITONE:float = log(2) / 12.0

func set_use_same_enemy_hit_sfx(value: bool) -> void:
	_use_same_enemy_hit_sfx = value

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
		if sfx.can_be_played():
			sfx.update_audio_count(1)
			var new_2D_audio = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			
			new_2D_audio.position = location
			new_2D_audio.bus = sfx.bus
			new_2D_audio.stream = sfx.sound_effect
			new_2D_audio.volume_db = sfx.volume
			if change_length:
				new_2D_audio.pitch_scale = (new_2D_audio.stream.get_length() / desired_length)
			else:
				new_2D_audio.pitch_scale = _semitones_to_pitch_scale(sfx.semitones.pick_random())
			new_2D_audio.finished.connect(sfx.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			
			if sfx.play_while_paused:
				new_2D_audio.process_mode = Node.PROCESS_MODE_ALWAYS
			else:
				new_2D_audio.process_mode = Node.PROCESS_MODE_PAUSABLE
			
			new_2D_audio.play()
			return new_2D_audio
	else:
		push_warning("SFX type not found: ", sfx_type)
	return null

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
			new_audio.pitch_scale = _semitones_to_pitch_scale(sfx.semitones.pick_random())
			new_audio.finished.connect(sfx.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			
			if sfx.play_while_paused:
				new_audio.process_mode = Node.PROCESS_MODE_ALWAYS
			else:
				new_audio.process_mode = Node.PROCESS_MODE_PAUSABLE
			
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
	new_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	new_audio.bus = "Music"
	add_child(new_audio)
	new_audio.stream = map_1_victory
	new_audio.volume_db = -12
	new_audio.play()
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

func play_enemy_hit(is_crit:bool = false, sfx_type:SoundEffectSettings.SOUND_EFFECT_TYPE = SoundEffectSettings.SOUND_EFFECT_TYPE.ON_ENEMY_HIT, location:Vector2 = Vector2.INF):
	if _enemy_hit_limit_counter < _enemy_hit_limit:
		if _local_player == null:
			_local_player = GameState.get_local_player()
			if _local_player == null:
				return
		
		var new_audio = null
		
		if (
				location != Vector2.INF
				and location.distance_squared_to(_local_player.global_position) < MAX_SQUARED_ENEMY_HIT_DISTANCE
		):
		# Otherwise, create new audio with sfx_type
			if _use_same_enemy_hit_sfx:
				new_audio = create_audio_at_location(location, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_ENEMY_HIT)
			else:
				new_audio = create_audio_at_location(location, sfx_type)
		
		if new_audio != null:
			_enemy_hit_limit_counter += 1
			
			var pitch_scale = new_audio.pitch_scale
			if is_crit:
				pitch_scale = new_audio.pitch_scale + 0.06
			new_audio.pitch_scale = pitch_scale
			
			new_audio.finished.connect(
				func():
					_enemy_hit_limit_counter -= 1
			)
	
func _semitones_to_pitch_scale(semitones:float) -> float:
	return 1.0 + (semitones * LOG_SEMITONE)
