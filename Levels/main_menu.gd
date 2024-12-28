extends Control

# Will be spawned in the Lobby screen. Clicking allows the player to join a lobby
const lobby_button_scene: Resource = preload("res://UI/lobby_button.tscn")

## The first screen shown when the game is started.
@export var main_menu: Control
## The screen to host or join a lobby.
@export var lobby_list: Control
## The scroll box showing lobbies available to join.
@export var lobbies_list_container: VBoxContainer
## The screen showing players in the current lobby.
@export var lobby: Control
## Contains the UI elements for displaying the players in the lobby.
@export var players_holder: BoxContainer
## The button to begin the actual game. Disabled for clients that are not the host.
@export var start_game_button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.player_list_changed.connect(self.refresh_lobby)
	
	setup_lobby_screen()


func _process(_delta: float) -> void:
	pass


func _on_quit_button_button_down() -> void:
	get_tree().quit()


func _on_lobby_button_button_down() -> void:
	main_menu.hide()
	lobby_list.show()


func _on_host_button_button_down() -> void:
	if GameState.USING_GODOT_STEAM:
		GameState.host_lobby(Steam.getPersonaName())
		
		# Show the lobby that you're in after clicking the "Host" button.
		lobby_list.hide()
		lobby.show()
		refresh_lobby()
	else:
		MultiplayerManager.create_server()


func _on_join_button_button_down() -> void:
	MultiplayerManager.create_client()


func request_lobby_list() -> void:
	for button in lobbies_list_container.get_children():
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
				lobbies_list_container.add_child(lobby_button)
				lobby_button.pressed.connect(
					func():
						# Join the lobby
						lobby_list.hide()
						lobby.show()
						start_game_button.hide()
						
						GameState.join_lobby(
							lobby_id,
							Steam.getPersonaName())
				)
	)
	
	request_lobby_list()


# Updates the lobby view to show the players that are connected
func refresh_lobby() -> void:
	var i = 0
	for player_id in GameState.players:
		players_holder.get_child(i).get_node("ID").text = str(player_id)
		players_holder.get_child(i).get_node("Username").text = GameState.players[player_id]
		i += 1


func _on_lobby_list_back_button_button_down() -> void:
	lobby_list.hide()
	main_menu.show()


# The button that only the lobby host can press to begin the shooting part of the game.
func _on_start_game_button_down() -> void:
	GameState.start_game()
