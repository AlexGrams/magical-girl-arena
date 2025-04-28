class_name MainMenu
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
@export var players_holder: Control
## Contains buttons for selecting a character
@export var character_select_button_holder: Control
## Components for displaying selected character information on the Lobby screen.
@export var information_name: RichTextLabel
@export var information_description: RichTextLabel
@export var information_powerup_texture: TextureRect
@export var information_powerup_description: RichTextLabel
@export var information_ult_texture: TextureRect
@export var information_ult_description: RichTextLabel
## The button to begin the actual game. Disabled for clients that are not the host.
@export var start_game_button: Button


var _player_containers: Array[LobbyPlayerCharacterContainer] = []
var _character_select_buttons: Array[CharacterSelectButton] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.player_list_changed.connect(self.refresh_lobby)
	GameState.lobby_closed.connect(
		func():
			# Does the same thing as leaving the lobby by clicking the "Leave" button.
			lobby.hide()
			lobby_list.show()
			request_lobby_list()
	)
	
	for container in players_holder.get_children():
		_player_containers.append(container)
	
	# TODO: Bind events to each button to change the character when button is pressed.
	for button: Button in character_select_button_holder.get_children():
		_character_select_buttons.append(button)
		button.pressed.connect(func():
			_on_character_select_button_pressed(button)
		)
	
	setup_lobby_screen()


func _process(_delta: float) -> void:
	pass


#region main
# Exit the game.
func _on_quit_button_button_down() -> void:
	get_tree().quit()


# Go from the main menu to the lobby list.
func _on_lobby_button_button_down() -> void:
	main_menu.hide()
	lobby_list.show()
	request_lobby_list()
#endregion

#region lobby_list
# Start a new lobby.
func _on_host_button_button_down() -> void:
	if GameState.USING_GODOT_STEAM:
		GameState.host_lobby(Steam.getPersonaName())
	else:
		MultiplayerManager.join_multiplayer_lobby_using_enet()
		if not multiplayer.is_server():
			start_game_button.hide()
	
	# Show the lobby that you're in after clicking the "Host" button.
	lobby_list.hide()
	lobby.show()
	refresh_lobby()
	update_character_description()


# Go from the lobby list to the main menu.
func _on_lobby_list_back_button_button_down() -> void:
	lobby_list.hide()
	main_menu.show()


# Refresh the lobby list
func request_lobby_list() -> void:
	for button in lobbies_list_container.get_children():
		button.queue_free()
	
	if GameState.USING_GODOT_STEAM:
		Steam.requestLobbyList()


# Adds list of joinable lobbies to the lobby screen.
func setup_lobby_screen() -> void:
	if GameState.USING_GODOT_STEAM:
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
					lobby_button.set_host_name(lobby_name)
					lobby_button.set_playercount(str(player_count))
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
#endregion

#region lobby
# The button that only the lobby host can press to begin the shooting part of the game.
func _on_start_game_button_down() -> void:
	GameState.start_game()


# Leave a game lobby. Goes back to the lobby list.
func _on_leave_button_down() -> void:
	GameState.disconnect_local_player()
	lobby.hide()
	lobby_list.show()
	request_lobby_list()


# Updates the lobby view to show the players that are connected and their characters.
@rpc("any_peer", "call_local")
func refresh_lobby() -> void:
	var i = 0
	for player_id in GameState.players:
		_player_containers[i].set_properties(
			GameState.players[player_id]["name"], 
			player_id,
			GameState.players[player_id]["character"]
		)
		i += 1
	
	# Reset the remaining holders
	while i < GameState.MAX_PLAYERS:
		_player_containers[i].clear_properties()
		i += 1


# Updates the displayed sprite to represent the player's currently selected character.
# Called after that player changes their character.
@rpc("any_peer", "call_local")
func refresh_player_sprite(player_id: int) -> void:
	for container: LobbyPlayerCharacterContainer in _player_containers:
		if container.player_id == player_id:
			container.set_properties(
				GameState.players[player_id]["name"], 
				player_id,
				GameState.players[player_id]["character"]
			)


# Changes the client's selected character.
func _on_character_select_button_pressed(button: CharacterSelectButton) -> void:
	GameState.set_character.rpc(multiplayer.get_unique_id(), button.character)
	refresh_player_sprite.rpc(multiplayer.get_unique_id())
	update_character_description()


# Sets the text and images in the character information panel to match the client's character.
func update_character_description() -> void:
	if multiplayer.get_unique_id() not in GameState.players:
		await multiplayer.connected_to_server
	
	var character: Constants.Character = GameState.players[multiplayer.get_unique_id()]["character"]
	
	var data: CharacterData = null
	match(character):
		Constants.Character.GOTH:
			data = load("res://Player/CharacterResourceFiles/character_data_goth.tres")
		Constants.Character.SWEET:
			data = load("res://Player/CharacterResourceFiles/character_data_sweet.tres")
		_:
			print("uh oh")
	
	information_name.text = "[center]" + data.name + "[/center]"
	information_description.text = data.description
	information_powerup_texture.texture = data.base_powerup_texture
	information_powerup_description.text = data.base_powerup_name
	information_ult_texture.texture = data.ult_texture
	information_ult_description.text = data.ult_name

#endregion
