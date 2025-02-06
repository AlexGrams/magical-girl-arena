extends Node
# Manager class for saving and loading persistent data.

const SAVE_GAME_PATH := "user://savedata.json"


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
