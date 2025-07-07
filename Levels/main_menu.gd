class_name MainMenu
extends Control

# Will be spawned in the Lobby screen. Clicking allows the player to join a lobby
const lobby_button_scene: Resource = preload("res://UI/lobby_button.tscn")
## Time in seconds that it takes for the Lobby List to automatically refresh.
const LOBBY_LIST_AUTO_REFRESH_INTERVAL: float = 10.0

## The first screen shown when the game is started.
@export var main_menu: Control
## The screen for changing the game's settings.
@export var settings: Control
## The screen for the shop
@export var shop: Shop
## The screen to host or join a lobby.
@export var lobby_list: Control
## Appears on the Lobby List while waiting for the list of available lobbies.
@export var lobbies_list_searching_overlay: Control = null
## The scroll box showing lobbies available to join.
@export var lobbies_list_container: VBoxContainer
## The screen showing players in the current lobby.
@export var lobby: Control
## The screen telling the player that they're connecting to a game
@export var connecting_screen: Control
## Parent of the UI elements displaying lobby visibility option.
@export var lobby_visibility_holder: Control 
## For selecting who can join this lobby.
@export var lobby_visibility_option_button: OptionButton
## Contains the UI elements for displaying the players in the lobby.
@export var players_holder: Control
## Contains buttons for selecting a character
@export var character_select_button_holder: Control
## Components for displaying selected character information on the Lobby screen.
@export var information_name: Label
@export var information_description: Label
@export var information_powerup_label: Label
@export var information_powerup_texture: TextureRect
@export var information_powerup_description: Label
@export var information_ult_label: Label
@export var information_ult_texture: TextureRect
@export var information_ult_description: Label
## The button to begin the actual game. Disabled for clients that are not the host.
@export var start_game_label: Label
## Character that is visible on the main menu and their nametag.
@export var main_menu_character_sprite: CharacterAnimatedSprite2D
@export var main_menu_character_label: Label
## Container for buttons on main menu.
@export var main_menu_button_container: VBoxContainer
@export var version_label: Label

## Current time until automatically refreshing the Lobby List.
var _lobby_list_refresh_timer: float = 0.0
var _player_containers: Array[LobbyPlayerCharacterContainer] = []
var _character_select_buttons: Array[CharacterSelectButton] = []
## The location that these menus should be in when in focus. 
## Used for animating the UI when switching screens.
var _main_menu_original_pos: Vector2
var _settings_original_pos: Vector2
var _lobby_list_original_pos: Vector2
var _lobby_original_pos: Vector2
var _shop_original_pos: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.player_list_changed.connect(self.refresh_lobby)
	GameState.lobby_closed.connect(
		func():
			# Does the same thing as leaving the lobby by clicking the "Leave" button.
			_switch_screen_animation(lobby, lobby_list, _lobby_list_original_pos)
			request_lobby_list()
	)
	
	# Exit the Lobby screen automatially if we attempt to join an invalid lobby.
	if GameState.USING_GODOT_STEAM:
		Steam.lobby_data_update.connect(
			func(success: int, _lobby_id: int, _member_id: int):
				if success == 0:
					# Was not successful in getting new lobby data. Presumably this only happens
					# when joining an invalid lobby, so return to the lobby select screen.
					GameState.disconnect_local_player()
					_switch_screen_animation(lobby, lobby_list, _lobby_list_original_pos)
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
	
	# Setting pivot offset for properly scaling on mouse hover.
	# This is done here because it cannot be set in the inspector
	for label in main_menu_button_container.get_children():
		label.pivot_offset = Vector2(0, label.size.y / 2)

	_main_menu_original_pos = main_menu.position
	_settings_original_pos = settings.position
	_lobby_list_original_pos = lobby_list.position
	_lobby_original_pos = lobby.position
	_shop_original_pos = shop.position
	
	
	_set_main_menu_character()
	version_label.change_text("Version " + ProjectSettings.get_setting("application/config/version"))
	setup_lobby_screen()


func _process(delta: float) -> void:
	# Lobby list auto refresh
	if lobby_list.visible:
		_lobby_list_refresh_timer -= delta
		if _lobby_list_refresh_timer <= 0.0:
			request_lobby_list()


#region main
# Exit the game.
func _on_quit_button_button_down() -> void:
	get_tree().quit()


# Go from the main menu to the lobby list.
func _on_lobby_button_button_down() -> void:
	_switch_screen_animation(main_menu, lobby_list, _lobby_list_original_pos)
	request_lobby_list()


## Switch to the settings screen.
func _on_settings_button_down() -> void:
	_switch_screen_animation(main_menu, settings, _settings_original_pos)
	
## Switch to the shop screen.
func _on_shop_button_down() -> void:
	_switch_screen_animation(main_menu, shop, _settings_original_pos)
	shop.update_all_quantities()


func _set_main_menu_character() -> void:
	var random_char = -1
	while random_char == -1:
		random_char = Constants.Character.values().pick_random()
	main_menu_character_sprite.set_character(random_char)
	main_menu_character_sprite.set_read_input(false)
	main_menu_character_sprite.set_model_scale(3)
	main_menu_character_label.text = _get_character_data(random_char).name if _get_character_data(random_char).display_name == "" else _get_character_data(random_char).display_name


## Go from any other menu screen to the lobby screen.
func switch_any_to_lobby() -> void:
	settings.hide()
	lobby_list.hide()
	lobby.hide()
	main_menu.show()
	_switch_screen_animation(main_menu, lobby, _lobby_original_pos)

#endregion


#region settings

func _on_settings_back_button_down() -> void:
	_set_main_menu_character()
	_switch_screen_animation(settings, main_menu , _main_menu_original_pos)

#endregion


#region lobby_list
# Start a new lobby.
func _on_host_button_button_down() -> void:
	if GameState.USING_GODOT_STEAM:
		GameState.host_lobby(Steam.getPersonaName())
		start_game_label.show()
	else:
		MultiplayerManager.join_multiplayer_lobby_using_enet()
		if not multiplayer.is_server():
			start_game_label.hide()
	
	# Show the lobby that you're in after clicking the "Host" button.
	lobby_visibility_holder.visible = true
	lobby_visibility_option_button.selected = 1
	_switch_screen_animation(lobby_list, lobby, _lobby_original_pos)
	refresh_lobby()
	update_character_description()


# Go from the lobby list to the main menu.
func _on_lobby_list_back_button_button_down() -> void:
	_set_main_menu_character()
	_switch_screen_animation(lobby_list, main_menu , _main_menu_original_pos)


## Refresh the lobby list
func request_lobby_list() -> void:
	for button in lobbies_list_container.get_children():
		button.queue_free()
	lobbies_list_searching_overlay.show()
	
	if GameState.USING_GODOT_STEAM:
		Steam.requestLobbyList()
	
	_lobby_list_refresh_timer = LOBBY_LIST_AUTO_REFRESH_INTERVAL


# Adds list of joinable lobbies to the lobby screen.
func setup_lobby_screen() -> void:
	if GameState.USING_GODOT_STEAM:
		# TODO: Maybe make the region a setting? This current one is the most restrictive.
		Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_CLOSE)
		
		Steam.lobby_match_list.connect(
			# lobbies: Array[int] (lobby IDs) - All lobbies in the specified region for this game.
			func(lobbies: Array):
				# We need to separately get all the lobbies that are joinable by friends only.
				for i in range(0, Steam.getFriendCount()):
					var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
					var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)
					
					if not game_info.is_empty():
						# They are playing a game, check if it's the same game as ours
						var lobby_id = game_info['lobby']
						
						if game_info['id'] != Steam.getAppID() or lobby_id is not int:
							# Either not in this game, or not in a lobby
							continue
						
						if not lobbies.has(lobby_id):
							lobbies.append(lobby_id)
							Steam.requestLobbyData(lobby_id)
				
				for lobby_id: int in lobbies:
					var lobby_name: String = Steam.getLobbyData(lobby_id, "Name")
					var player_count: int = Steam.getNumLobbyMembers(lobby_id)
					
					# Don't make the button if we don't have good data for this lobby.
					if lobby_name == "" or player_count == 0:
						continue
					
					var lobby_button: LobbyButton = lobby_button_scene.instantiate()
					
					# Set up the button for this lobby
					lobby_button.set_host_name(lobby_name)
					lobby_button.set_playercount(str(player_count))
					lobby_button.set_ping(Steam.getLobbyData(lobby_id, "Location"))
					lobbies_list_container.add_child(lobby_button)
					lobby_button.pressed.connect(
						func():
							_on_lobby_button_pressed(lobby_id)
					)
				lobbies_list_searching_overlay.hide()
		)
	
	request_lobby_list()


## Asynchronous function to connect to another server using the Steamworks API.
func _on_lobby_button_pressed(lobby_id: int) -> void:
	# First, get the most recent information about the lobby.
	# If this doesn't work, don't join and refresh the lobby list.
	var lobby_data_request_successful: bool = Steam.requestLobbyData(lobby_id)
	if not lobby_data_request_successful:
		push_error("Unable to send request for lobby data to the Steam servers.")
		request_lobby_list()
		return
	connecting_screen.show()
	
	# Async wait until the lobby information is returned.
	await Steam.lobby_data_update
	
	# Don't join a lobby that nobody is in.
	if Steam.getNumLobbyMembers(lobby_id) <= 0:
		connecting_screen.hide()
		request_lobby_list()
		return
	
	# Join the lobby
	GameState.join_lobby(
		lobby_id,
		Steam.getPersonaName())
	
	# There should be at least one other player in the lobby. Wait until we get someone 
	# else's data in the lobby.
	# TODO: Maybe add a timeout so we don't get stuck here?
	await GameState.player_list_changed
	
	refresh_lobby()
	lobby_visibility_holder.visible = false
	_switch_screen_animation(lobby_list, lobby, _lobby_original_pos)
	start_game_label.hide()

#endregion

#region lobby
# The button that only the lobby host can press to begin the shooting part of the game.
func _on_start_game_button_down() -> void:
	_hide_main_menu.rpc()
	GameState.start_game()


@rpc("any_peer", "call_local")
func _hide_main_menu() -> void:
	self.hide()


## Change which other players can join this lobby.
func _on_lobby_visibility_option_button_item_selected(index: int) -> void:
	if not GameState.USING_GODOT_STEAM and not OS.has_feature("release"):
		return
	
	match(index):
		0: # Public
			Steam.setLobbyType(GameState.lobby_id, Steam.LOBBY_TYPE_PUBLIC)
		1: # Friends only
			Steam.setLobbyType(GameState.lobby_id, Steam.LOBBY_TYPE_FRIENDS_ONLY)
		2: # Closed
			Steam.setLobbyType(GameState.lobby_id, Steam.LOBBY_TYPE_PRIVATE)


# Leave a game lobby. Goes back to the lobby list.
func _on_leave_button_down() -> void:
	GameState.disconnect_local_player()
	_switch_screen_animation(lobby, lobby_list, _lobby_list_original_pos)
	request_lobby_list()

# Show shop, but don't leave lobby.
func _on_shop_button_down_from_lobby() -> void:
	_switch_screen_animation(lobby, lobby_list, _lobby_list_original_pos)
	request_lobby_list()


## Updates the lobby view to show connected players, their characters, and the local player's
## character information.
@rpc("any_peer", "call_local")
func refresh_lobby() -> void:
	# Don't try to refresh the lobby if we're in a game right now.
	if GameState.game_running:
		return
	
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
	
	update_character_description()


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
	# TODO: Fix this or whatever
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	GameState.set_character.rpc(multiplayer.get_unique_id(), button.character)
	refresh_player_sprite.rpc(multiplayer.get_unique_id())
	update_character_description()


# Sets the text and images in the character information panel to match the client's character.
func update_character_description() -> void:
	if multiplayer.get_unique_id() not in GameState.players:
		await multiplayer.connected_to_server
	
	var character: Constants.Character = GameState.players[multiplayer.get_unique_id()]["character"]
	
	var data: CharacterData = _get_character_data(character)
	
	information_name.change_text(data.name if data.display_name == "" else data.display_name)
	information_description.text = data.description
	information_powerup_texture.texture = data.base_powerup_texture
	information_powerup_label.change_text(data.base_powerup_name)
	information_powerup_description.text = load(data.base_powerup_data).upgrade_description_list[5]
	information_ult_texture.texture = data.ult_texture
	information_ult_label.change_text(data.ult_name)
	information_ult_description.text = data.ult_description


## Switches from the lobby screen to the main menu
func quit_to_main_menu() -> void:
	_switch_screen_animation(lobby, main_menu, _main_menu_original_pos)

#endregion

#region shop

# Switches from shop screen to the main menu
func from_shop_to_main_menu() -> void:
	shop.update_coins()
	_set_main_menu_character()
	_switch_screen_animation(shop, main_menu, _main_menu_original_pos)

# Used to show shop without leaving current screen
func show_shop() -> void:
	# If shop is off-screen, move it to center
	shop.update_all_quantities()
	if shop.position != _shop_original_pos:
		shop.position = _shop_original_pos
	shop.get_node("DimBackground").show()
	shop.get_node("HideShop_Label").show()
	shop.get_node("ReturntoMainMenu_Label").hide()
	shop.show()


# Used to hide shop after using show shop
func hide_shop() -> void:
	shop.get_node("DimBackground").hide()
	shop.get_node("HideShop_Label").hide()
	shop.get_node("ReturntoMainMenu_Label").show()
	shop.hide()
	# Move shop back off-screen
	shop.position = Vector2(-(shop.size.x), shop.position.y)
	
#endregion

func _switch_screen_animation(from_screen: Control, to_screen: Control, to_screen_original_pos: Vector2):
	# Sort of a hack to prevent the connecting screen from blocking input erroneously.
	# Assumes we never switch screens while waiting to connect.
	connecting_screen.hide()
	
	to_screen.position = Vector2(-(to_screen.size.x), to_screen.position.y)
	to_screen.show()
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(to_screen, "position", to_screen_original_pos, 0.25)
	await tween.tween_property(from_screen, "position", Vector2(-(from_screen.size.x), from_screen.position.y), 0.25).finished
	from_screen.hide()
	to_screen.show()

func _get_character_data(character: Constants.Character) -> CharacterData:
	return Constants.CHARACTER_DATA[character]
