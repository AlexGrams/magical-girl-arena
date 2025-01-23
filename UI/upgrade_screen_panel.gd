extends Panel


# Parent of the upgrade panel UI objects.
@export var upgrade_panels_holder: Control = null

# All upgrades that the player can acquire in the game. Chosen from at random when upgrading.
# Contains Array of [PowerupName, Sprite, UpgradeDescription]
var all_upgrades: Array = []
var upgrade_panels: Array = []
var boomerang_sprite = preload("res://Peach.png")
var revolving_sprite = preload("res://Orange.png")
var orbit_sprite = preload("res://Coconut.png")

signal upgrade_chosen(title)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in upgrade_panels_holder.get_children():
		upgrade_panels.append(child)
	
	$HBoxContainer/IndividualUpgradePanel.set_powerup("Boomerang", boomerang_sprite, "Increase damage")
	$HBoxContainer/IndividualUpgradePanel2.set_powerup("Revolving", revolving_sprite, "Increase damage")
	$HBoxContainer/IndividualUpgradePanel3.set_powerup("Orbit", orbit_sprite, "Increase damage")
	
	all_upgrades.append(["Boomerang", boomerang_sprite, "Increase damage"])
	all_upgrades.append(["Revolving", revolving_sprite, "Increase damage"])
	all_upgrades.append(["Orbit", orbit_sprite, "Increase damage"])
	
	for child in $HBoxContainer.get_children():
		child.upgrade_chosen.connect(on_upgrade_chosen)


# Show the upgrade screen and set up the options provided to the player.
func setup():
	var player_character: PlayerCharacterBody2D = GameState.get_local_player()
	
	# If the player is maxed out on the number of unique powerups they can have, then 
	# choose some amount (3 in this case) to upgrade randomly.
	if len(player_character.powerups) >= player_character.MAX_POWERUPS:
		print("Powerups are maxed out")
	# Otherwise, choose randomly from the whole pool up abilities.
	else:
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
		random_powerup_list.shuffle()
		var i = 0
		while i < len(upgrade_panels) and i < len(random_powerup_list):
			upgrade_panels[i].set_powerup(
				random_powerup_list[i][0],
				random_powerup_list[i][1],
				random_powerup_list[i][2]
			)
			upgrade_panels[i].show()
			i += 1
		# Hide remaining panels
		while i < len(upgrade_panels):
			upgrade_panels[i].hide()
			i += 1
	
	show()


func on_upgrade_chosen(title):
	print("CHOSEN UPGRADE: " + str(title))
	upgrade_chosen.emit(title)
