class_name Shop
extends Control

## Displays number of player's coins
@export var coins_label:Label

## Buttons for items available for purchase
@export var reroll_item:Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_gold_display(GameState.get_gold())
	update_all_quantities()
	
	## Connect all item buttons
	reroll_item.button.button_down.connect(buy_reroll)

# Updates the coin display text over time
func update_coins() -> void:
	# Rapidly update gold display until it reaches actual gold value
	var tween = create_tween()
	tween.tween_method(set_gold_display, int(coins_label.text), GameState.get_gold(), 0.5)


#region Buying Functions
## Used to buy a standard reroll
func buy_reroll() -> void:
	# Don't buy if at max quantity or if not enough money
	if GameState.rerolls >= get_max_quantity(reroll_item):
		return
	spend_gold(reroll_item)
	
	GameState.rerolls += 1
	reroll_item.update_quantity(GameState.rerolls)
	
	SaveManager.save_game()
#endregion

#region Helper Functions
## Helper functions

## Update the displayed quantity of all item buttons.
func update_all_quantities() -> void:
	reroll_item.update_quantity(GameState.rerolls)


func spend_gold(item:Control):
	# TODO: Save gold?
	if has_enough_gold(item):
		GameState.set_gold(GameState.get_gold() - get_price(item))
		update_coins()

func get_price(item:Control) -> int:
	return item.item_data.price

func get_max_quantity(item:Control) -> int:
	return item.item_data.max_quantity

func has_enough_gold(item:Control) -> bool:
	return GameState.get_gold() >= item.item_data.price

func set_gold_display(new_value:int) -> void:
	coins_label.text = str(new_value)
#endregion
