extends Panel


## Every powerup that can be acquired in the game. Chosen from at random when upgrading.
@export var all_powerup_data: Array[PowerupData] = []
# Parent of the upgrade panel UI objects.
@export var upgrade_panels_holder: Control = null
# Window that shows up saying how many players are still choosing upgrades.
@export var players_selecting_upgrades_window: Control = null
# Parent of the PlayReadyIndicators
@export var player_ready_indicator_holder: Control = null

# All upgrades that the player can acquire in the game. Chosen from at random when upgrading.
# Contains Array of [PowerupName, Sprite, UpgradeDescription]
var all_upgrades: Array = []
var upgrade_panels: Array = []
var ready_indicators: Array = []
var boomerang_sprite = preload("res://Peach.png")
var revolving_sprite = preload("res://Orange.png")
var orbit_sprite = preload("res://Coconut.png")
# How many players are done choosing upgrades.
var players_done_selecting_upgrades: int = 0

signal upgrade_chosen(title)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in upgrade_panels_holder.get_children():
		upgrade_panels.append(child)
	for child in player_ready_indicator_holder.get_children():
		ready_indicators.append(child)
	
	$HBoxContainer/IndividualUpgradePanel.set_powerup("Boomerang", boomerang_sprite, "Increase damage")
	$HBoxContainer/IndividualUpgradePanel2.set_powerup("Revolving", revolving_sprite, "Increase damage")
	$HBoxContainer/IndividualUpgradePanel3.set_powerup("Orbit", orbit_sprite, "Increase damage")
	
	all_upgrades.append(["Boomerang", boomerang_sprite, "Increase damage"])
	all_upgrades.append(["Revolving", revolving_sprite, "Increase damage"])
	all_upgrades.append(["Orbit", orbit_sprite, "Increase damage"])
	
	for child in $HBoxContainer.get_children():
		child.upgrade_chosen.connect(_on_upgrade_chosen)


# Display a random selection of upgrades for the player to choose from.
# upgrade_data must contain valid upgrade possibilities. 
func _show_random_upgrade_choices(upgrade_data: Array) -> void:
	upgrade_data.shuffle()
	var i = 0
	while i < len(upgrade_panels) and i < len(upgrade_data):
		upgrade_panels[i].set_powerup(
			upgrade_data[i][0],
			upgrade_data[i][1],
			upgrade_data[i][2]
		)
		upgrade_panels[i].show()
		i += 1
	
	# Hide remaining panels
	if i == 0:
		push_error("There were no valid powerups to upgrade!")
		_on_upgrade_chosen("")
		return
	
	while i < len(upgrade_panels):
		upgrade_panels[i].hide()
		i += 1


# Notify relevant systems that this player has selected an upgrade.
# Called after one of the upgrade panels has been clicked.
func _on_upgrade_chosen(title):
	# This signal is connected to the player's function for adding or upgrading the powerup.
	upgrade_chosen.emit(title)
	GameState.player_selected_upgrade.rpc_id(1)
	
	# Set up and show the screen saying how many players are still choosing their upgrades.
	upgrade_panels_holder.hide()
	increment_players_selecting_upgrades.rpc()
	players_selecting_upgrades_window.show()
	
	# TODO: For showing a screen when others are selecting abilities:
	# - Emit from upgrade_chosen.
	# - Player is connected to that signal, so it is notified to add the powerup
	# - Server is notified that this player has selected their upgrade
	# - Notify everyone that this player has selected their upgrade
	# -- This and the previous might be able to be combined into one RPC. But on who?
	# -- No, make them separate. GameState needs to do something, and the UpgradeScreenPanel
	#    needs to do something.
	# - Once everyone has their upgrade, hide the UpgradeScreenPanel


# Update the displayed count of how many players are still selecting their upgrades.
@rpc("any_peer", "call_local")
func increment_players_selecting_upgrades() -> void:
	players_done_selecting_upgrades += 1
	
	if players_done_selecting_upgrades >= GameState.connected_players:
		hide()
	
	var i = 0
	# Ready players
	while i < players_done_selecting_upgrades:
		ready_indicators[i].show()
		ready_indicators[i].set_is_ready(true)
		i += 1
	# Not ready players
	while i < GameState.connected_players:
		ready_indicators[i].show()
		ready_indicators[i].set_is_ready(false)
		i += 1
	# Hide remaining indicators
	while i < GameState.MAX_PLAYERS:
		ready_indicators[i].hide()
		i += 1


# Show the upgrade screen and set up the options provided to the player.
func setup():
	var player_character: PlayerCharacterBody2D = GameState.get_local_player()
	players_done_selecting_upgrades = 0
	players_selecting_upgrades_window.hide()
	upgrade_panels_holder.show()
	
	if len(player_character.powerups) >= player_character.MAX_POWERUPS:
		# If the player is maxed out on the number of unique powerups they can have, then 
		# choose some amount (3 in this case) to upgrade randomly.
		var upgrade_choices: Array[String] = []
		var random_powerups = []
		
		for powerup: Powerup in player_character.powerups:
			if powerup.current_level < powerup.max_level:
				upgrade_choices.append(powerup.powerup_name)
		
		for powerup in all_upgrades:
			if powerup[0] in upgrade_choices:
				random_powerups.append(powerup)
		
		_show_random_upgrade_choices(random_powerups)
	else:
		# Otherwise, choose randomly from the whole pool up abilities.
		var random_powerup_list = all_upgrades.duplicate()

		# Remove powerups from the random list that can't be upgraded anymore.
		var powerups_to_remove = []
		for powerup: Powerup in player_character.powerups:
			if powerup.current_level >= powerup.max_level:
				powerups_to_remove.append(powerup.powerup_name)
		if len(powerups_to_remove) > 0:
			var i = 0
			while i < len(random_powerup_list):
				if random_powerup_list[i][0] in powerups_to_remove:
					random_powerup_list.remove_at(i)
					i -= 1
				i += 1
		
		# Choose some powerups at random to show to the player
		_show_random_upgrade_choices(random_powerup_list)
	
	show()
