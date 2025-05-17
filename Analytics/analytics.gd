extends PlayFabEvent
## Manages game analytics through Microsoft Azure PlayFab: https://playfab.com/
## Docs: https://learn.microsoft.com/en-us/gaming/playfab/get-started/  

const ANALYTICS_ENABLED = true

## All the data relevant to this client that is generated during one match. 
var _telemetry_payload: Dictionary = {}


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
	
	# Let's think about how we want to record data while the game is running.
	# We know that we want to send telemetry when the game is over.
	# Let's connect something to the "end game" signal, then use that to send
	# the data when the game finishes.
	# Since there might be some legal stuff that makes it so that we have to give players
	# the option to not send data, we should have each client keep track of their own data.
	# That makes it easier to keep track of things like powerups chosen since these things aren't 
	# replicated. Will be harder to keep track of damage and health since only the server knows that.


## Processes result returned by sending telemetry event to PlayFab server.
func _telemerty_event_callback(_data: Dictionary) -> void:
	pass


@rpc("authority", "call_local")
func set_match_id(id: int) -> void:
	_telemetry_payload["match_id"] = id


func set_character(character_name: String) -> void:
	_telemetry_payload["character"] = character_name


func add_level_up_time(time: int) -> void:
	if not _telemetry_payload.has("level_up_times"):
		_telemetry_payload["level_up_times"] = []
	_telemetry_payload["level_up_times"].append(time)
	print(_telemetry_payload)


## Sends all the data this client gathered during the match to the PlayFab server. This data will 
## then be visible on our dashboard.
@rpc("authority", "call_local")
func send_match_data() -> void:
	if not is_multiplayer_authority():
		return
	
	write_title_player_telemetry_event("match_data", _telemetry_payload, _telemerty_event_callback)
	print("Data sent!")
	print(_telemetry_payload)
	
	# Clear the telemetry payload. This might be an issue if we want to retry sending the payload
	# in case it fails.
	_telemetry_payload = {}
