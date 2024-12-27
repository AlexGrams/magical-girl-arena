extends Control

# Will be spawned in the Lobby screen. Clicking allows the player to join a lobby
const lobby_button_scene: Resource = preload("res://UI/lobby_button.tscn")

@export var lobbies_list: VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_lobby_screen()


func _process(_delta: float) -> void:
	pass


func _on_quit_button_button_down() -> void:
	get_tree().quit()


func _on_lobby_button_button_down() -> void:
	$Main.visible = false
	$Lobby.visible = true


func _on_host_button_button_down() -> void:
	if GameState.USING_GODOT_STEAM:
		# TODO: Toggle lobby scrollbox visibility.
		GameState.host_lobby(Steam.getPersonaName())
		
		# Show the lobby that you're in after clicking the "Host" button.
		#refresh_lobby()
	else:
		MultiplayerManager.create_server()


func _on_join_button_button_down() -> void:
	MultiplayerManager.create_client()


func request_lobby_list() -> void:
	for button in lobbies_list.get_children():
		button.queue_free()
	
	Steam.requestLobbyList()


# Adds list of joinable lobbies to the lobby screen.
func setup_lobby_screen() -> void:
	# TODO: Maybe make the region a setting? This current one is the most restrictive.
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_CLOSE)
	
	Steam.lobby_match_list.connect(
		# lobbies: Array[int] (lobby IDs) - All lobbies in the specified region for this game.
		func(lobbies: Array):
			for lobby_id: int in lobbies:
				var lobby_name: String = Steam.getLobbyData(lobby_id, "Name")
				var player_count: int = Steam.getNumLobbyMembers(lobby_id)
				var lobby_button: Button = lobby_button_scene.instantiate()
				
				# Set up the button for this lobby
				lobby_button.set_text(str(lobby_name, ": ", player_count, " players"))
				lobbies_list.add_child(lobby_button)
				lobby_button.pressed.connect(
					func():
						# Join the lobby
						# TODO: Hide "Join Lobby" screen, show the individual "Lobby" screen.
						GameState.join_lobby(
							lobby_id,
							Steam.getPersonaName())
				)
	)
	
	request_lobby_list()
