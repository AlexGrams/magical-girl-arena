extends Control

@export var item_data:ShopItemData
@export var current_quantity:int = 0

## Nodes
@export var button:TextureButton
@export var item_icon:TextureRect
@export var item_name:Label
@export var item_desc:Label
@export var item_price:Label
@export var item_quantity:Label
@export var disabled_panel:ColorRect
@export var disabled_message:Label

## Panel background images
@export var panel_texture:Texture2D
@export var panel_disabled_texture:Texture2D

## Themes
@export var name_theme:Theme
@export var name_disabled_theme:Theme
@export var desc_theme:Theme
@export var desc_disabled_theme:Theme

## Particles used on purchase
@export var coin_particles:PackedScene

var is_disabled:bool = false

# Used for on hover
var _original_scale:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_original_scale = button.scale
	
	# Set up text and visuals
	item_icon.texture = item_data.icon
	item_name.text = item_data.item_name
	item_desc.text = item_data.item_desc
	item_price.text = str(item_data.price)
	disabled_message.text = item_data.get_sold_message()
	update_quantity(current_quantity)


func update_quantity(new_quantity:int) -> void:
	current_quantity = new_quantity
	
	# Update quantity text
	item_quantity.text = str(current_quantity) + "/" + str(item_data.max_quantity)
	
	# If max quantity has been reached, disable button
	if current_quantity >= item_data.max_quantity:
		button.disabled = true
		item_icon.texture = item_data.disabled_icon
		item_name.theme = name_disabled_theme
		item_desc.theme = desc_disabled_theme
		disabled_panel.show()
	# If button is disabled, but not at max quantity, reenable
	elif button.disabled:
		button.disabled = false
		item_icon.texture = item_data.icon
		item_name.theme = name_theme
		item_desc.theme = desc_theme
		disabled_panel.hide()
		

func play_purchase_animation() -> void:
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.ITEM_PURCHASED)
	add_child(coin_particles.instantiate())

func _on_mouse_entered():
	if button.disabled:
		return
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_HOVER)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2.ONE * 1.10, 0.1)

func _on_mouse_exited():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)
