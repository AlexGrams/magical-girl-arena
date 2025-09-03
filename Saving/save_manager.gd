extends Node
## Manager class for saving and loading persistent data.

const SAVE_GAME_PATH := "user://savedata.json"
const SETTINGS_PATH := "user://settings.json"
const DEFAULT_DISPLAY_MODE := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
const DEFAULT_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 1.0
const DEFAULT_BULLET_OPACITY := 1.0


func _ready() -> void:
	load_settings()


## Write the configured game settings to disk.
func save_settings(
		display_mode: DisplayServer.WindowMode, 
		volume: float, 
		music_volume: float,
		bullet_opacity: float
	) -> void:
	var config = ConfigFile.new()

	config.set_value("display", "display_mode", display_mode)
	config.set_value("sound", "volume", volume)
	config.set_value("music", "volume", music_volume)
	config.set_value("gameplay", "bullet_opacity", bullet_opacity)

	config.save(SETTINGS_PATH)


# Saves data to disk. Should be modified when new data to save is added.
@rpc("any_peer", "call_local")
func save_game() -> void:
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	
	if save_file == null:
		printerr("Error when opening file %s: %s", SAVE_GAME_PATH, FileAccess.get_open_error())
		return
	
	var save_data := {
		"gold": GameState.get_gold(),
		"rerolls": GameState.rerolls,
		"perm_rerolls": GameState.perm_rerolls,
		"powerup_rerolls": GameState.powerup_rerolls,
		"artifact_rerolls": GameState.artifact_rerolls,
		"map_complete_garden": GameState.map_complete_garden,
		"map_complete_desert": GameState.map_complete_desert
	}
	
	var json_string := JSON.stringify(save_data)
	save_file.store_line(json_string)


## Read and apply the settings for the game. Creates the settings file if one doesn't exist already.
func load_settings() -> void:
	# Create a new settings file if one doesn't exist.
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings(
			DEFAULT_DISPLAY_MODE, 
			DEFAULT_VOLUME, 
			DEFAULT_MUSIC_VOLUME,
			DEFAULT_BULLET_OPACITY
		)

	var settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		return

	# Apply settings
	SettingsManager.apply_display_mode(settings.get_value("display", "display_mode"))
	SettingsManager.apply_volume(settings.get_value("sound", "volume"))
	## TODO: QUICK FIX FOR TESTING FOR RIGHT NOW.
	if settings.get_value("music", "volume") == null:
		settings.set_value("music", "volume", DEFAULT_MUSIC_VOLUME)
	SettingsManager.apply_music_volume(settings.get_value("music", "volume"))
	SettingsManager.apply_bullet_opacity(settings.get_value("gameplay", "bullet_opacity", DEFAULT_BULLET_OPACITY))
	SettingsManager.set_settings(settings)


# Load data from disk and set variables. Should be modified when new data to save is added.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		return # Error! We don't have a save to load.

	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	var json_string = save_file.get_line()
	var json = JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	# Get the data from the JSON object.
	var save_data: Dictionary = json.data
	
	# Set game variables from the loaded data
	GameState.set_gold(save_data["gold"])
	if save_data.has("rerolls"):
		GameState.rerolls = save_data["rerolls"]
	if save_data.has("perm_rerolls"):
		GameState.perm_rerolls = save_data["perm_rerolls"]
	if save_data.has("powerup_rerolls"):
		GameState.powerup_rerolls = save_data["powerup_rerolls"]
	if save_data.has("artifact_rerolls"):
		GameState.artifact_rerolls = save_data["artifact_rerolls"]
	if save_data.has("map_complete_garden"):
		GameState.map_complete_garden = save_data["map_complete_garden"]
	if save_data.has("map_complete_desert"):
		GameState.map_complete_desert = save_data["map_complete_desert"]
