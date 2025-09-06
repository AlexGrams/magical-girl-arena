extends Panel


## How many upgrade choices are not multiplayer-specific.
const MAX_NORMAL_UPGRADES: int = 3
## How many choices will be offered to acquire a new multiplayer-specific powerup.
const MAX_NEW_MULTIPLAYER_POWERUPS: int = 1
## Folder containing all PowerupData files.
const POWERUP_DATA_PATH: String = "res://Powerups/PowerupDataResourceFiles/"
## Folder containing all ArtifactData files.
const ARTIFACT_DATA_PATH: String = "res://Artifacts/ArtifactDataResourceFiles/"

## Chance of being offered a new multiplayer-specific powerup.
@export_range(0.0, 1.0) var multiplayer_powerup_chance: float = 0.5
## Parent of the upgrade panel UI objects.
@export var upgrade_panels_holder: Control = null
## Button for rerolling the provided upgrades.
@export var reroll_button: ButtonHover = null
## Button for rerolling and getting only Powerups.
@export var powerup_reroll_button: ButtonHover = null
## Button for rerolling and getting only Artifacts.
@export var artifact_reroll_button: ButtonHover = null
## Window that shows up saying how many players are still choosing upgrades.
@export var players_selecting_upgrades_window: Control = null
## Parent of the PlayReadyIndicators
@export var player_ready_indicator_holder: Control = null

# All upgrade panels.
var upgrade_panels: Array[UpgradePanel] = []
# How many players are done choosing upgrades.
var players_done_selecting_upgrades: int = 0

## The local player.
var _player_character: PlayerCharacterBody2D = null
## Every powerup that can be acquired in the game. Chosen from at random when upgrading.
var _all_powerup_data: Array[PowerupData] = []
## Every artifact that can be acquired in the game.
var _all_artifact_data: Array[ArtifactData] = []
## Map of String to ItemData
var _item_name_to_itemdata: Dictionary = {}
## Map of String to PowerupData
var _powerup_name_to_powerupdata := {}
## Map of String to ArtifactData
var _artifact_name_to_artifactdata := {}
## The multiplayer Powerups that this player could be given.
var _multiplayer_upgrade_choices: Array[PowerupData] = []
## Current powerup level that corresponds to upgrade_choices. 0 = Not yet obtained
var _upgrade_levels: Dictionary = {}
## Current names of upgrades that are being displayed.
var _displayed_upgrade_names: Array[String] = []
## Map of int (player multiplayer ID) to Array[String] (list of upgrades names from ItemData.name).
## Only contains information on the server.
var _player_possible_upgrades: Dictionary = {}
## Keys are String names of unique artifacts that any player has acquired for the rest of the game.
## Acquired unique artifacts are not offered to other players. Only contains information on the server.
var _owned_unique_artifacts: Dictionary = {}
## Contains a key if a unique artifact with that name has been assigned to someone. 
## Only contains information on the server.
var _assigned_unique_artifacts: Dictionary = {}
## Displays which characters have finished selecting their upgrade.
var _ready_indicators: Array[PlayerReadyIndicator] = []
## Maps each connecter player's multiplayer unique ID to their corresponding PlayerReadyIndicator.
var _player_id_to_ready_indicator: Dictionary = {}

signal upgrade_chosen(title)
signal stat_upgrade_chosen(stat_type: Constants.StatUpgrades)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child: UpgradePanel in upgrade_panels_holder.get_children():
		upgrade_panels.append(child)
		child.upgrade_chosen.connect(_on_upgrade_chosen)
		child.upgrade_stat_chosen.connect(_on_stat_upgrade_chosen)
	
	# Set up ready indicators
	for child in player_ready_indicator_holder.get_children():
		_ready_indicators.append(child)
	
	# Load PowerupData files
	for powerup_data_file_name: String in DirAccess.open(POWERUP_DATA_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in powerup_data_file_name:
			powerup_data_file_name = powerup_data_file_name.trim_suffix('.remap')
		
		var powerup_data: PowerupData = ResourceLoader.load(POWERUP_DATA_PATH + powerup_data_file_name)
		if powerup_data != null:
			_all_powerup_data.append(powerup_data)
	
	# Set up the powerup name to PowerupData map
	for powerupdata: PowerupData in _all_powerup_data:
		_powerup_name_to_powerupdata[powerupdata.name] = powerupdata
		_item_name_to_itemdata[powerupdata.name] = powerupdata
	
	# Load ArtifactData files
	for artifact_data_file_name: String in DirAccess.open(ARTIFACT_DATA_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in artifact_data_file_name:
			artifact_data_file_name = artifact_data_file_name.trim_suffix('.remap')
		
		var artifact_data: ArtifactData = ResourceLoader.load(ARTIFACT_DATA_PATH + artifact_data_file_name)
		if artifact_data != null:
			_all_artifact_data.append(artifact_data)
	
	# Set up artifact name to ArtifactData map
	for artifactdata: ArtifactData in _all_artifact_data:
		_artifact_name_to_artifactdata[artifactdata.name] = artifactdata
		_item_name_to_itemdata[artifactdata.name] = artifactdata


# Show the upgrade screen and set up the options provided to the player.
func setup():
	_player_character = GameState.get_local_player()
	players_done_selecting_upgrades = 0
	players_selecting_upgrades_window.hide()
	upgrade_panels_holder.show()
	reroll_button.show()
	powerup_reroll_button.show()
	artifact_reroll_button.show()
	
	# Set up PlayerReadyIndicator icons
	for i in range(GameState.connected_players):
		var id = GameState.players.keys()[i]
		_ready_indicators[i].set_sprite(GameState.players[id]["character"])
		_ready_indicators[i].set_is_ready(false)
		_player_id_to_ready_indicator[id] = _ready_indicators[i]
	
	_generate_and_show_random_upgrade_choices()
	
	show()


## Makes a random list of powerups to obtain or upgrade, and update the stats upgrade panel.
func _generate_and_show_random_upgrade_choices() -> void:
	# Powerups or Artifacts that can be upgraded 
	var upgrade_choices: Array[ItemData] = []
	
	_multiplayer_upgrade_choices.clear()
	_upgrade_levels.clear()
	
	# Add artifact choices that the player doesn't have already.
	if len(_player_character.artifacts) < _player_character.MAX_ARTIFACTS:
		var artifactdata_dict: Dictionary = _artifact_name_to_artifactdata.duplicate()
		
		for owned_artifact: Artifact in _player_character.artifacts:
			if not owned_artifact.allow_duplicates:
				artifactdata_dict.erase(owned_artifact.artifactdata.name)
		
		for artifact_data: ArtifactData in artifactdata_dict.values():
			if artifact_data.can_acquire():
				upgrade_choices.append(artifact_data)
				_upgrade_levels[artifact_data.name] = 0
	
	# Decide which Powerups can possibly be upgraded
	if len(_player_character.powerups) >= _player_character.MAX_POWERUPS:
		# If the player is maxed out on the number of unique powerups they can have, then 
		# choose some amount (3 in this case) to upgrade randomly.
		
		for powerup: Powerup in _player_character.powerups:
			if powerup.current_level < powerup.max_level:
				upgrade_choices.append(_powerup_name_to_powerupdata[powerup.powerup_name])
				if powerup.current_level == 4 and powerup.is_signature:
					_upgrade_levels[powerup.powerup_name] = 5
				else:
					_upgrade_levels[powerup.powerup_name] = powerup.current_level
	else:
		# Otherwise, choose randomly from the whole pool up abilities.
		var powerups_to_remove = []
		upgrade_choices.append_array(_all_powerup_data.duplicate())
		
		# If in inventory, get current level for each powerup
		for data: PowerupData in _all_powerup_data:
			var found_powerup := false
			for powerup in _player_character.powerups:
				if data.name == powerup.powerup_name:
					found_powerup = true
					if powerup.current_level == 4 and powerup.is_signature:
						_upgrade_levels[powerup.powerup_name] = 5
					else:
						_upgrade_levels[powerup.powerup_name] = powerup.current_level
					break
			if not found_powerup:
				if data.is_multiplayer:
					# Multiplayer Powerups can only be granted by the last special slot. 
					powerups_to_remove.append(data.name)
					_multiplayer_upgrade_choices.append(data)
				_upgrade_levels[data.name] = 0

		# Remove powerups from the random list that can't be upgraded anymore.
		for powerup: Powerup in _player_character.powerups:
			if powerup.current_level >= powerup.max_level:
				powerups_to_remove.append(powerup.powerup_name)
		if len(powerups_to_remove) > 0:
			var i = 0
			while i < len(upgrade_choices):
				if upgrade_choices[i].name in powerups_to_remove:
					upgrade_choices.remove_at(i)
					i -= 1
				i += 1
	
	# TODO: Make this whole function use String arrays if this works
	var upgrade_choice_names: Array[String] = []
	for upgrade: ItemData in upgrade_choices:
		upgrade_choice_names.append(upgrade.name)
	
	_update_reroll_button()
	_update_powerup_reroll_button()
	_update_artifact_reroll_button()
	upgrade_panels_holder.hide()
	
	_report_upgrade_choices.rpc_id(1, upgrade_choice_names)


## Records the upgrades that can be displayed for each player. Called after each client calculates 
## which upgrades they can display. Once all clients send their choices, sends a random selection of 
## upgrades back to each player. Ensures that no two players are given an option for the same unique
## Artifact. Only call on server.
@rpc("any_peer", "call_local", "reliable")
func _report_upgrade_choices(upgrade_names: Array[String]) -> void:
	if not multiplayer.is_server():
		push_warning("Only call on the server.")
		return
	
	_player_possible_upgrades[multiplayer.get_remote_sender_id()] = upgrade_names
	if len(_player_possible_upgrades) >= GameState.connected_players:
		# We have everyone's information now. Assign upgrades to players.
		
		# Random order in which we determine who gets what upgrades.
		var assign_order: Array = _player_possible_upgrades.keys()
		
		_assigned_unique_artifacts = _owned_unique_artifacts.duplicate()
		
		assign_order.shuffle()
		for id in assign_order:
			_show_random_upgrade_choices.rpc_id(id, _make_valid_random_upgrade_choices(id))


## Get a list of upgrades for a certain player. Keeps track of unique Artifacts that are assigned.
func _make_valid_random_upgrade_choices(id: int) -> Array[String]:
	# Names of upgrades that will be given to the current player.
	var selected_upgrades: Array[String] = []
	# Assigned upgrades to this player, making sure that unique Artifacts that are assigned haven't
	# already been given to someone else.
	var current_upgrade_names: Array[String] = _player_possible_upgrades[id]
	
	current_upgrade_names.shuffle()
	
	var i: int = 0
	while i < len(current_upgrade_names) and len(selected_upgrades) < MAX_NORMAL_UPGRADES:
		if not _assigned_unique_artifacts.has(current_upgrade_names[i]):
			selected_upgrades.append(current_upgrade_names[i])
			# If the upgrade we just added was a unique Artifact, than add it to our set
			# of assigned unique upgrades.
			if (
					_artifact_name_to_artifactdata.has(current_upgrade_names[i])
					and _artifact_name_to_artifactdata[current_upgrade_names[i]].is_unique
			):
				_assigned_unique_artifacts[current_upgrade_names[i]] = true
		i += 1
	
	return selected_upgrades


func _make_valid_random_powerup_upgrade_choices(id: int) -> Array[String]:
	var selected_upgrades: Array[String] = []
	var current_upgrade_names: Array[String] = _player_possible_upgrades[id]
	
	# Get only powerup upgrades.
	current_upgrade_names.shuffle()
	for upgrade_name: String in current_upgrade_names:
		if _powerup_name_to_powerupdata.has(upgrade_name):
			selected_upgrades.append(upgrade_name)
			if len(selected_upgrades) >= MAX_NORMAL_UPGRADES:
				break
	
	return selected_upgrades


func _make_valid_random_artifact_upgrade_choices(id: int) -> Array[String]:
	var selected_upgrades: Array[String] = []
	var current_upgrade_names: Array[String] = _player_possible_upgrades[id]
	
	current_upgrade_names.shuffle()
	
	var i: int = 0
	while i < len(current_upgrade_names) and len(selected_upgrades) < MAX_NORMAL_UPGRADES:
		# Only add artifacts.
		if (
				_artifact_name_to_artifactdata.has(current_upgrade_names[i])
				and not _assigned_unique_artifacts.has(current_upgrade_names[i])
		):
			selected_upgrades.append(current_upgrade_names[i])
			# If the upgrade we just added was a unique Artifact, than add it to our set
			# of assigned unique upgrades.
			if (
					_artifact_name_to_artifactdata.has(current_upgrade_names[i])
					and _artifact_name_to_artifactdata[current_upgrade_names[i]].is_unique
			):
				_assigned_unique_artifacts[current_upgrade_names[i]] = true
		i += 1
	
	return selected_upgrades


## Display a selection of upgrades for the player to choose from.
## upgrade_names must contain valid upgrade possibilities. Only call from the server.
@rpc("any_peer", "call_local", "reliable")
func _show_random_upgrade_choices(upgrade_names: Array[String]) -> void:
	_displayed_upgrade_names = upgrade_names
	var i = 0
	while i < MAX_NORMAL_UPGRADES and i < len(upgrade_names):
		upgrade_panels[i].set_upgrade(_item_name_to_itemdata[upgrade_names[i]], _upgrade_levels)
		upgrade_panels[i].show()
		i += 1
	
	# Show multiplayer-specific upgrade choices
	if GameState.connected_players > 1 and randf() <= multiplayer_powerup_chance:
		_multiplayer_upgrade_choices.shuffle()
		var j = 0
		while j < MAX_NEW_MULTIPLAYER_POWERUPS and j < len(_multiplayer_upgrade_choices):
			upgrade_panels[i+j].set_upgrade(_multiplayer_upgrade_choices[j], _upgrade_levels)
			upgrade_panels[i+j].show()
			j += 1
		i += j
	
	# Hide remaining panels
	if i == 0:
		push_error("There were no valid powerups to upgrade!")
		return
	
	while i < len(upgrade_panels):
		upgrade_panels[i].hide()
		i += 1
	
	upgrade_panels_holder.show()
	_update_reroll_button()
	_update_powerup_reroll_button()
	_update_artifact_reroll_button()


func _on_reroll_button_down() -> void:
	_player_character.decrement_rerolls()
	
	for upgrade_panel: UpgradePanel in upgrade_panels:
		upgrade_panel.hide()
	
	_request_reroll_upgrade_choices.rpc_id(1, _displayed_upgrade_names)


func _on_powerup_reroll_button_down() -> void:
	GameState.powerup_rerolls -= 1
	
	for upgrade_panel: UpgradePanel in upgrade_panels:
		upgrade_panel.hide()
	
	_request_powerup_reroll_upgrade_choices.rpc_id(1, _displayed_upgrade_names)
	SaveManager.save_game()


func _on_artifact_reroll_button_down() -> void:
	GameState.artifact_rerolls -= 1
	
	for upgrade_panel: UpgradePanel in upgrade_panels:
		upgrade_panel.hide()
	
	_request_artifact_reroll_upgrade_choices.rpc_id(1, _displayed_upgrade_names)
	SaveManager.save_game()


## Get a new selection of upgrade choices, taking into account unique Artifacts that were assigned
## to other players.
@rpc("any_peer", "call_local", "reliable")
func _request_reroll_upgrade_choices(previous_upgrade_names: Array[String]) -> void:
	# ID of player who is rerolling.
	var id: int = multiplayer.get_remote_sender_id()
	
	# Free up unique artifacts that were assigned to the player requesting a reroll.
	for upgrade_name: String in previous_upgrade_names:
		if _assigned_unique_artifacts.has(upgrade_name):
			_assigned_unique_artifacts.erase(upgrade_name)
	
	_show_random_upgrade_choices.rpc_id(id, _make_valid_random_upgrade_choices(id))


@rpc("any_peer", "call_local", "reliable")
func _request_powerup_reroll_upgrade_choices(previous_upgrade_names: Array[String]) -> void:
	# ID of player who is rerolling.
	var id: int = multiplayer.get_remote_sender_id()
	
	# Free up unique artifacts that were assigned to the player requesting a reroll.
	for upgrade_name: String in previous_upgrade_names:
		if _assigned_unique_artifacts.has(upgrade_name):
			_assigned_unique_artifacts.erase(upgrade_name)
	
	_show_random_upgrade_choices.rpc_id(id, _make_valid_random_powerup_upgrade_choices(id))


@rpc("any_peer", "call_local", "reliable")
func _request_artifact_reroll_upgrade_choices(previous_upgrade_names: Array[String]) -> void:
	# ID of player who is rerolling.
	var id: int = multiplayer.get_remote_sender_id()
	
	# Free up unique artifacts that were assigned to the player requesting a reroll.
	for upgrade_name: String in previous_upgrade_names:
		if _assigned_unique_artifacts.has(upgrade_name):
			_assigned_unique_artifacts.erase(upgrade_name)
	
	_show_random_upgrade_choices.rpc_id(id, _make_valid_random_artifact_upgrade_choices(id))


## Update the text on the Reroll button
func _update_reroll_button() -> void:
	var rerolls = _player_character.get_rerolls()
	reroll_button.set_text("Reroll (" + str(rerolls) + " remaining)")
	reroll_button.set_interactable(rerolls > 0)


## Update the text on the Powerup Reroll button.
func _update_powerup_reroll_button() -> void:
	var powerup_rerolls = GameState.powerup_rerolls
	powerup_reroll_button.set_text("Powerup Reroll (" + str(powerup_rerolls) + " remaining)")
	powerup_reroll_button.set_interactable(powerup_rerolls > 0)


## Update the text on the Artifact Reroll button.
func _update_artifact_reroll_button() -> void:
	var artifact_rerolls = GameState.artifact_rerolls
	artifact_reroll_button.set_text("Charm Reroll (" + str(artifact_rerolls) + " remaining)")
	artifact_reroll_button.set_interactable(
			artifact_rerolls > 0 
			and len(_player_character.artifacts) < PlayerCharacterBody2D.MAX_ARTIFACTS
	)


## Notify relevant systems that this player has selected an upgrade.
## Called after one of the upgrade panels has been clicked.
func _on_upgrade_chosen(itemdata: ItemData):
	# This signal is connected to the player's function for adding or upgrading the powerup.
	upgrade_chosen.emit(itemdata)
	GameState.player_selected_upgrade.rpc_id(1)
	
	# If the upgrade was a unique artifact, prevent other players from getting that artifact on 
	# subsequent levelups.
	if itemdata is ArtifactData and itemdata.is_unique:
		_add_chosen_unique_artifact.rpc_id(1, itemdata.name)
	
	# Analytics: Record selection
	Analytics.add_upgrade_chosen(itemdata.name)
	
	# Set up and show the screen saying how many players are still choosing their upgrades.
	upgrade_panels_holder.hide()
	reroll_button.hide()
	powerup_reroll_button.hide()
	artifact_reroll_button.hide()
	
	_update_players_selecting_upgrades.rpc()
	players_selecting_upgrades_window.show()


## Records unique artifacts that any player has acquired, preventing other players from getting that 
## artifact as well. Only call on server.
@rpc("any_peer", "call_local", "reliable")
func _add_chosen_unique_artifact(unique_artifact_name: String) -> void:
	if not multiplayer.is_server():
		return
	
	_owned_unique_artifacts[unique_artifact_name] = true


## Notify relevant systems that a stat upgrade was chosen, then hide the upgrades menu.
func _on_stat_upgrade_chosen(stat_type: Constants.StatUpgrades) -> void:
	stat_upgrade_chosen.emit(stat_type)
	GameState.player_selected_upgrade.rpc_id(1)
	
	# Analytics: record selection
	Analytics.add_upgrade_chosen(Constants.StatUpgrades.keys()[stat_type])
	
	# Set up and show the screen saying how many players are still choosing their upgrades.
	upgrade_panels_holder.hide()
	reroll_button.hide()
	powerup_reroll_button.hide()
	artifact_reroll_button.hide()
	
	_update_players_selecting_upgrades.rpc()
	players_selecting_upgrades_window.show()


## Update the PlayerReadyIndicators showing how many players are still selecting their upgrades.
@rpc("any_peer", "call_local", "reliable")
func _update_players_selecting_upgrades() -> void:
	players_done_selecting_upgrades += 1
	
	if players_done_selecting_upgrades >= GameState.connected_players:
		_player_possible_upgrades.clear()
		hide()
	
	_player_id_to_ready_indicator[multiplayer.get_remote_sender_id()].set_is_ready(true)
	
	#var i = 0
	## Ready players
	#while i < players_done_selecting_upgrades:
		#_ready_indicators[i].show()
		#_ready_indicators[i].set_is_ready(true)
		#i += 1
	## Not ready players
	#while i < GameState.connected_players:
		#_ready_indicators[i].show()
		#_ready_indicators[i].set_is_ready(false)
		#i += 1
	for i in range(GameState.connected_players):
		_ready_indicators[i].show()
	# Hide remaining indicators
	for i in range(GameState.connected_players, GameState.MAX_PLAYERS):
		_ready_indicators[i].hide()
