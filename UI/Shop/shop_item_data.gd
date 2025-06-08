class_name ShopItemData
extends Resource
## Contains information about an item that can be bought in the shop

## When the max quantity has been bought, choose which message to show
enum SOLD_MESSAGE_TYPE
{
	MAXIMUM_REACHED,
	ALREADY_BOUGHT,
	ALREADY_UNLOCKED
}

@export var item_name:String
@export_multiline var item_desc:String
@export var icon:Texture2D
@export var disabled_icon:Texture2D # Used when the max quantity has been bought
@export var price:int
@export var max_quantity:int
@export var _sold_message:SOLD_MESSAGE_TYPE

var _current_rerolls:int = 0

func get_sold_message() -> String:
	match _sold_message:
		SOLD_MESSAGE_TYPE.ALREADY_BOUGHT:
			return("Already Purchased")
		SOLD_MESSAGE_TYPE.ALREADY_UNLOCKED:
			return("Already Unlocked")
		_:
			return("Maximum Reached")
