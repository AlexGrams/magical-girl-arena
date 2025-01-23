extends Panel


var boomerang_sprite = preload("res://Peach.png")
var revolving_sprite = preload("res://Orange.png")
var orbit_sprite = preload("res://Coconut.png")

signal upgrade_chosen(title)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/IndividualUpgradePanel.set_powerup("Boomerang", boomerang_sprite, "Increase damage")
	$HBoxContainer/IndividualUpgradePanel2.set_powerup("Revolving", revolving_sprite, "Increase damage")
	$HBoxContainer/IndividualUpgradePanel3.set_powerup("Orbit", orbit_sprite, "Increase damage")
	
	for child in $HBoxContainer.get_children():
		child.upgrade_chosen.connect(on_upgrade_chosen)


# Show the upgrade screen and set up the options provided to the player.
func setup():
	print("Wowie zowie")
	show()


func on_upgrade_chosen(title):
	print("CHOSEN UPGRADE: " + str(title))
	upgrade_chosen.emit(title)
