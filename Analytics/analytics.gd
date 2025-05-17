extends PlayFabEvent
## Manages game analytics through Microsoft Azure PlayFab: https://playfab.com/
## Docs: https://learn.microsoft.com/en-us/gaming/playfab/get-started/  

const ANALYTICS_ENABLED = true

## All the data relevant to this client that is generated during one match. 
var _telemetry_payload: Dictionary = {}
## Store damage values in an array that is unpacked into a dictionary when sending data.
## Makes it easier to update since we're not using branching logic.
var _powerup_damages: Array[float] = []


func _ready():
	if not ANALYTICS_ENABLED:
		return
	
	super._ready()
	
	# First, we need to log in to send any events to the PlayFab servers
	if PlayFabManager.client_config.login_type == PlayFabClientConfig.LoginType.LOGIN_CUSTOM_ID:
		# User doesn't have an anonymous account yet, so make a new one.
		var combined_info_request_params = GetPlayerCombinedInfoRequestParams.new()
		combined_info_request_params.show_all()
		var player_profile_view_constraints = PlayerProfileViewConstraints.new()
		combined_info_request_params.ProfileConstraints = player_profile_view_constraints
		
		PlayFabManager.client.login_with_custom_id(PlayFabManager.client_config.login_id, false, combined_info_request_params)
	else:
		push_warning("Creating new anonymous user")
		PlayFabManager.client.login_anonymous()
	
	_setup_telemetry_payload()
	
	# Let's think about how we want to record data while the game is running.
	# We know that we want to send telemetry when the game is over.
	# Let's connect something to the "end game" signal, then use that to send
	# the data when the game finishes.
	# Since there might be some legal stuff that makes it so that we have to give players
	# the option to not send data, we should have each client keep track of their own data.
	# That makes it easier to keep track of things like powerups chosen since these things aren't 
	# replicated. Will be harder to keep track of damage and health since only the server knows that.


## Processes result returned by sending telemetry event to PlayFab server.
func _send_telemerty_event_callback(_data: Dictionary) -> void:
	pass


## The analytic data we send to the PlayFab server is a dictionary, so we need to set its fields
## so that they are listed in the same order every time. 
func _setup_telemetry_payload() -> void:
	_telemetry_payload = {
		"match_id": 0,
		"character": "",
		"level_up_times": [],
		"upgrades_chosen": [],
		"powerup_1_damage": 0.0,
		"powerup_2_damage": 0.0,
		"powerup_3_damage": 0.0,
		"powerup_4_damage": 0.0,
		"powerup_5_damage": 0.0,
		"times_ulted": 0,
		"miniboss_hp_percent": 100,
		"boss_hp_percent": 100,
		"death_times": [],
		"final_game_time": 0
	}
	_powerup_damages = [0.0, 0.0, 0.0, 0.0, 0.0]


@rpc("authority", "call_local")
func set_match_id(id: int) -> void:
	_telemetry_payload["match_id"] = id


func set_character(character_name: String) -> void:
	_telemetry_payload["character"] = character_name


func set_miniboss_hp_percent(value: int) -> void:
	_telemetry_payload["miniboss_hp_percent"] = value


func set_boss_hp_percent(value: int) -> void:
	_telemetry_payload["boss_hp_percent"] = value


func set_final_game_time(time: int) -> void:
	_telemetry_payload["final_game_time"] = time


func add_level_up_time(time: int) -> void:
	_telemetry_payload["level_up_times"].append(time)


func add_upgrade_chosen(upgrade_name: String) -> void:
	_telemetry_payload["upgrades_chosen"].append(upgrade_name)


func add_powerup_damage(damage: float, index: int) -> void:
	_powerup_damages[index] += damage


func add_ult_count() -> void:
	_telemetry_payload["times_ulted"] += 1


func add_death_time(time: int) -> void:
	_telemetry_payload["death_times"].append(time)


## Sends all the data this client gathered during the match to the PlayFab server. This data will 
## then be visible on our dashboard.
@rpc("authority", "call_local")
func send_match_data() -> void:
	if not is_multiplayer_authority():
		return
	
	_telemetry_payload["powerup_1_damage"] = _powerup_damages[0]
	_telemetry_payload["powerup_2_damage"] = _powerup_damages[1]
	_telemetry_payload["powerup_3_damage"] = _powerup_damages[2]
	_telemetry_payload["powerup_4_damage"] = _powerup_damages[3]
	_telemetry_payload["powerup_5_damage"] = _powerup_damages[4]
	
	write_title_player_telemetry_event("match_data", _telemetry_payload, _send_telemerty_event_callback)
	print("Data sent: " + str(_telemetry_payload))
	
	# Clear the telemetry payload. This might be an issue if we want to retry sending the payload
	# in case it fails.
	_setup_telemetry_payload()
