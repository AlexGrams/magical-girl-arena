class_name UpgradeAnyScreenPanel
extends Panel
## Allows for acquiring or upgrading any Powerup in the game.


## Folder containing all PowerupData files.
const POWERUP_DATA_PATH: String = "res://Powerups/PowerupDataResourceFiles/"

## Parent of all the upgrade UI components.
@export var _upgrades_holder: Control = null
@export var _upgrade_any_screen_button_container: GridContainer = null
## Parent of all the player ready UI components.
@export var _players_selecting_upgrades_window: Control = null
@export var _player_ready_indicator_holder: Control = null
@export var _upgrade_any_button: String = ""

## How many players are done choosing upgrades.
var _players_done_selecting_upgrades: int = 0
## Displays which characters have finished selecting their upgrade.
var _ready_indicators: Array[PlayerReadyIndicator] = []
## Maps each connecter player's multiplayer unique ID to their corresponding PlayerReadyIndicator.
var _player_id_to_ready_indicator: Dictionary = {}
## True if this screen was activated in cheat mode. Allows unlimited powerup selection.
var _cheat_mode: bool = false


func _ready() -> void:
	# Add all powerups to the screen.
	var upgrade_any_button_resource: Resource = load(_upgrade_any_button)
	for powerup_data_file_name: String in DirAccess.open(POWERUP_DATA_PATH).get_files():
		# Exporting adds ".remap" to the end of .tres files.
		if '.tres.remap' in powerup_data_file_name:
			powerup_data_file_name = powerup_data_file_name.trim_suffix('.remap')
		
		var powerup_data: PowerupData = ResourceLoader.load(POWERUP_DATA_PATH + powerup_data_file_name)
		if powerup_data != null:
			var upgrade_any_button: UpgradeAnyPowerupButton = upgrade_any_button_resource.instantiate()
			upgrade_any_button.set_powerup(powerup_data)
			upgrade_any_button.upgrade_chosen.connect(_on_upgrade_chosen)
			_upgrade_any_screen_button_container.add_child(upgrade_any_button, true)
	
	# Set up ready indicators
	for child in _player_ready_indicator_holder.get_children():
		_ready_indicators.append(child)


## Set up and show the upgrade screen configuration.
func setup() -> void:
	_cheat_mode = false
	_players_selecting_upgrades_window.hide()
	_upgrades_holder.show()
	
	# Disable buttons if the player can't upgrade or select them.
	var player: PlayerCharacterBody2D = GameState.get_local_player()
	var max_level_powerups: Array[String] = []
	var owned_upgradable_powerups: Array[String] = []
	var max_powerups: bool = len(player.powerups) == PlayerCharacterBody2D.MAX_POWERUPS
	
	for powerup: Powerup in player.powerups:
		if powerup.current_level == powerup.max_level:
			max_level_powerups.append(powerup.powerup_name)
		else:
			owned_upgradable_powerups.append(powerup.powerup_name)
	
	for upgrade_button: UpgradeAnyPowerupButton in _upgrade_any_screen_button_container.get_children():
		if (
				(max_powerups and upgrade_button.get_powerup().name not in owned_upgradable_powerups)
				or (upgrade_button.get_powerup().name in max_level_powerups)
		):
			upgrade_button.hide()
	
	# Set up PlayerReadyIndicator icons
	for i in range(GameState.connected_players):
		var id = GameState.players.keys()[i]
		_ready_indicators[i].set_sprite(GameState.players[id]["character"])
		_ready_indicators[i].set_is_ready(false)
		_player_id_to_ready_indicator[id] = _ready_indicators[i]
	
	show()


## Alternate the visibility of this screen in cheat mode.
func toggle_cheat() -> void:
	if not visible:
		_cheat_mode = true
		_players_selecting_upgrades_window.hide()
		_upgrades_holder.show()
		show()
	else:
		hide()


## Notify relevant systems that this player has selected an upgrade.
## Called after one of the upgrade buttons has been clicked.
func _on_upgrade_chosen():
	# Do nothing if in cheat mode.
	if _cheat_mode:
		return
	
	GameState.player_selected_upgrade.rpc_id(1)
	
	# Set up and show the screen saying how many players are still choosing their upgrades.
	_upgrades_holder.hide()
	
	_update_players_selecting_upgrades.rpc()
	_players_selecting_upgrades_window.show()


## Update the PlayerReadyIndicators showing how many players are still selecting their upgrades.
@rpc("any_peer", "call_local", "reliable")
func _update_players_selecting_upgrades() -> void:
	_players_done_selecting_upgrades += 1
	
	if _players_done_selecting_upgrades >= GameState.connected_players:
		hide()
	
	_player_id_to_ready_indicator[multiplayer.get_remote_sender_id()].set_is_ready(true)

	for i in range(GameState.connected_players):
		_ready_indicators[i].show()
	# Hide remaining indicators
	for i in range(GameState.connected_players, GameState.MAX_PLAYERS):
		_ready_indicators[i].hide()
