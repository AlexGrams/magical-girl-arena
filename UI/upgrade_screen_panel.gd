extends Panel


## Every powerup that can be acquired in the game. Chosen from at random when upgrading.
@export var all_powerup_data: Array[PowerupData] = []
## Parent of the upgrade panel UI objects.
@export var upgrade_panels_holder: Control = null
## Button for rerolling the provided upgrades.
@export var reroll_button: Button = null
## Text for reroll button
@export var reroll_label: Label = null
## Box visual for the reroll button
@export var reroll_texture: TextureRect = null
## Window that shows up saying how many players are still choosing upgrades.
@export var players_selecting_upgrades_window: Control = null
## Parent of the PlayReadyIndicators
@export var player_ready_indicator_holder: Control = null

var upgrade_panels: Array[UpgradePanel] = []
# How many players are done choosing upgrades.
var players_done_selecting_upgrades: int = 0

# Map of String to PowerupData
var _powerup_name_to_powerupdata := {}
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
		child.upgrade_powerup_chosen.connect(_on_upgrade_chosen)
		child.upgrade_stat_chosen.connect(_on_stat_upgrade_chosen)
	
	# Set up ready indicators
	for child in player_ready_indicator_holder.get_children():
		_ready_indicators.append(child)
	
	# Set up the powerup name to PowerupData map
	for powerupdata: PowerupData in all_powerup_data:
		_powerup_name_to_powerupdata[powerupdata.name] = powerupdata


# Show the upgrade screen and set up the options provided to the player.
func setup():
	players_done_selecting_upgrades = 0
	players_selecting_upgrades_window.hide()
	upgrade_panels_holder.show()
	reroll_button.show()
	
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
	var player_character: PlayerCharacterBody2D = GameState.get_local_player()
	# Mixed array of either PowerupData or Constants.StatUpgrades
	var upgrade_choices: Array = []
	
	# Decide which Powerups can possibly be upgraded
	if len(player_character.powerups) >= player_character.MAX_POWERUPS:
		# If the player is maxed out on the number of unique powerups they can have, then 
		# choose some amount (3 in this case) to upgrade randomly.
		
		for powerup: Powerup in player_character.powerups:
			if powerup.current_level < powerup.max_level:
				upgrade_choices.append(_powerup_name_to_powerupdata[powerup.powerup_name])
	else:
		# Otherwise, choose randomly from the whole pool up abilities.
		upgrade_choices.append_array(all_powerup_data.duplicate())

		# Remove powerups from the random list that can't be upgraded anymore.
		var powerups_to_remove = []
		for powerup: Powerup in player_character.powerups:
			if powerup.current_level >= powerup.max_level:
				powerups_to_remove.append(powerup.powerup_name)
		if len(powerups_to_remove) > 0:
			var i = 0
			while i < len(upgrade_choices):
				if upgrade_choices[i].name in powerups_to_remove:
					upgrade_choices.remove_at(i)
					i -= 1
				i += 1
	
	# Decide which stats can be upgraded.
	for stat_name in range(len(Constants.StatUpgrades)):
		upgrade_choices.append(stat_name)
	
	_show_random_upgrade_choices(upgrade_choices)
	
	# Update the text on the Reroll button
	var rerolls = player_character.get_rerolls()
	reroll_label.text = "Reroll (" + str(rerolls) + " remaining)"
	if rerolls <= 0:
		reroll_button.disabled = true
		reroll_texture.modulate = Color.DIM_GRAY
	else:
		reroll_button.disabled = false
		reroll_texture.modulate = Color.WHITE


# Display a random selection of upgrades for the player to choose from.
# upgrade_data must contain valid upgrade possibilities. 
func _show_random_upgrade_choices(upgrade_data: Array) -> void:
	upgrade_data.shuffle()
	var i = 0
	while i < len(upgrade_panels) and i < len(upgrade_data):
		upgrade_panels[i].set_upgrade(upgrade_data[i])
		upgrade_panels[i].show()
		i += 1
	
	# Hide remaining panels
	if i == 0:
		push_error("There were no valid powerups to upgrade!")
		return
	
	while i < len(upgrade_panels):
		upgrade_panels[i].hide()
		i += 1


func _on_reroll_button_down() -> void:
	var player_character: PlayerCharacterBody2D = GameState.get_local_player()
	player_character.decrement_rerolls()
	
	_generate_and_show_random_upgrade_choices()


# Notify relevant systems that this player has selected an upgrade.
# Called after one of the upgrade panels has been clicked.
func _on_upgrade_chosen(powerupdata: PowerupData):
	# This signal is connected to the player's function for adding or upgrading the powerup.
	upgrade_chosen.emit(powerupdata)
	GameState.player_selected_upgrade.rpc_id(1)
	
	# Analytics: Record selection
	Analytics.add_upgrade_chosen(powerupdata.name)
	
	# Set up and show the screen saying how many players are still choosing their upgrades.
	upgrade_panels_holder.hide()
	reroll_button.hide()
	
	_update_players_selecting_upgrades.rpc()
	players_selecting_upgrades_window.show()


## Notify relevant systems that a stat upgrade was chosen, then hide the upgrades menu.
func _on_stat_upgrade_chosen(stat_type: Constants.StatUpgrades) -> void:
	stat_upgrade_chosen.emit(stat_type)
	GameState.player_selected_upgrade.rpc_id(1)
	
	# Analytics: record selection
	Analytics.add_upgrade_chosen(Constants.StatUpgrades.keys()[stat_type])
	
	# Set up and show the screen saying how many players are still choosing their upgrades.
	upgrade_panels_holder.hide()
	reroll_button.hide()
	
	_update_players_selecting_upgrades.rpc()
	players_selecting_upgrades_window.show()


## Update the PlayerReadyIndicators showing how many players are still selecting their upgrades.
@rpc("any_peer", "call_local")
func _update_players_selecting_upgrades() -> void:
	players_done_selecting_upgrades += 1
	
	if players_done_selecting_upgrades >= GameState.connected_players:
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
