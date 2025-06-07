extends Node
## Manager class for saving and loading persistent data.

const SAVE_GAME_PATH := "user://savedata.json"
const SETTINGS_PATH := "user://settings.json"
const DEFAULT_DISPLAY_MODE := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
const DEFAULT_VOLUME := 1.0


func _ready() -> void:
	load_settings()


## Write the configured game settings to disk.
func save_settings(display_mode: DisplayServer.WindowMode, volume: float) -> void:
	var config = ConfigFile.new()

	config.set_value("display", "display_mode", display_mode)
	config.set_value("sound", "volume", volume)

	config.save(SETTINGS_PATH)


# Saves data to disk. Should be modified when new data to save is added.
@rpc("any_peer", "call_local")
func save_game() -> void:
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	
	if save_file == null:
		printerr("Error when opening file %s: %s", SAVE_GAME_PATH, FileAccess.get_open_error())
		return
	
	var save_data := {
		"gold": GameState.get_gold()
	}
	
	var json_string := JSON.stringify(save_data)
	save_file.store_line(json_string)


## Read and apply the settings for the game. Creates the settings file if one doesn't exist already.
func load_settings() -> void:
	# Create a new settings file if one doesn't exist.
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings(DEFAULT_DISPLAY_MODE, DEFAULT_VOLUME)

	var settings = ConfigFile.new()
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		return

	# Apply settings
	SettingsManager.apply_display_mode(settings.get_value("display", "display_mode"))
	SettingsManager.apply_volume(settings.get_value("sound", "volume"))
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
	var save_data = json.data
	
	# Set game variables from the loaded data
	GameState.set_gold(save_data["gold"])
