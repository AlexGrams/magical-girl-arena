extends PlayFabEvent
## Manages game analytics through Microsoft Azure PlayFab: https://playfab.com/
## Docs: https://learn.microsoft.com/en-us/gaming/playfab/get-started/  


func _ready():
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
	print("Attempting login...")
	
	PlayFabManager.client.logged_in.connect(func(_login_result: LoginResult):
		# Next, try to send a telemetry event.
		#var event_name := "test_telemetry_event"
		#var payload := {
			#"key_string": "value",
			#"key_float": 1.5,
			#"key_int": 3
		#}
		#
		#write_title_player_telemetry_event(event_name, payload)
		print("Telemetry event sent!")
	)
	
