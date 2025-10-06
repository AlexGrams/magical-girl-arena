class_name Shop
extends Control

## Displays number of player's coins
@export var coins_label:Label
## Appears when the Shop is brought up from the Lobby screen.
@export var hide_button: Button = null

## Buttons for items available for purchase
@export_group("Rerolls")
@export var reroll_item:Control
@export var perm_reroll_item:Control
@export var powerup_reroll_item:Control = null
@export var artifact_reroll_item:Control = null

@export_group("Characters")
@export var vale_item: Control = null

### TO ADD A NEW ITEM:
## Connect button in _ready()
## Create buy function in #region Buying Functions
## Update quantity in update_all_quantities()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_gold_display(GameState.get_gold())
	update_all_quantities()
	
	## Connect all item buttons
	reroll_item.button.button_down.connect(buy_reroll)
	perm_reroll_item.button.button_down.connect(buy_perm_reroll)
	powerup_reroll_item.button.button_down.connect(buy_powerup_reroll)
	artifact_reroll_item.button.button_down.connect(buy_artifact_reroll)


# Updates the coin display text over time
func update_coins() -> void:
	# Rapidly update gold display until it reaches actual gold value
	var tween = create_tween()
	tween.tween_method(set_gold_display, int(coins_label.text), GameState.get_gold(), 0.5)


#region Buying Functions
## Used to buy a standard reroll
func buy_reroll() -> void:
	# Don't buy if at max quantity or if not enough money
	if GameState.rerolls >= get_max_quantity(reroll_item) or !has_enough_gold(reroll_item):
		return
	
	spend_gold(reroll_item)
	GameState.rerolls += 1
	reroll_item.update_quantity(GameState.rerolls)
	
	SaveManager.save_game()

## Used to buy permanent rerolls
func buy_perm_reroll() -> void:
	# Don't buy if at max quantity or if not enough money
	if GameState.perm_rerolls >= get_max_quantity(perm_reroll_item) or !has_enough_gold(perm_reroll_item):
		return
	
	spend_gold(perm_reroll_item)
	GameState.perm_rerolls += 1
	perm_reroll_item.update_quantity(GameState.perm_rerolls)
	
	SaveManager.save_game()


## Buy a reroll that only shows powerups.
func buy_powerup_reroll() -> void:
	if GameState.powerup_rerolls >= get_max_quantity(powerup_reroll_item) or !has_enough_gold(powerup_reroll_item):
		return
	
	spend_gold(powerup_reroll_item)
	GameState.powerup_rerolls += 1
	powerup_reroll_item.update_quantity(GameState.powerup_rerolls)
	
	SaveManager.save_game()


## Buy a reroll that only shows artifacts.
func buy_artifact_reroll() -> void:
	if GameState.artifact_rerolls >= get_max_quantity(artifact_reroll_item) or !has_enough_gold(artifact_reroll_item):
		return
	
	spend_gold(artifact_reroll_item)
	GameState.artifact_rerolls += 1
	artifact_reroll_item.update_quantity(GameState.artifact_rerolls)
	
	SaveManager.save_game()
#endregion

#region Helper Functions
## Helper functions

## Update the displayed quantity of all item buttons.
func update_all_quantities() -> void:
	reroll_item.update_quantity(GameState.rerolls)
	perm_reroll_item.update_quantity(GameState.perm_rerolls)
	powerup_reroll_item.update_quantity(GameState.powerup_rerolls)
	artifact_reroll_item.update_quantity(GameState.artifact_rerolls)
	set_gold_display(GameState.get_gold())


func spend_gold(item:Control) -> void:
	if has_enough_gold(item):
		GameState.set_gold(GameState.get_gold() - get_price(item))
		update_coins()
		item.play_purchase_animation()


func get_price(item:Control) -> int:
	return item.item_data.price


func get_max_quantity(item:Control) -> int:
	return item.item_data.max_quantity


func has_enough_gold(item:Control) -> bool:
	return GameState.get_gold() >= item.item_data.price


func set_gold_display(new_value:int) -> void:
	coins_label.text = str(new_value)
#endregion
