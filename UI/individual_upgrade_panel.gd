class_name UpgradePanel
extends Control

## Powerup/charm name
@export var _item_label: Label
## Powerup/charm image
@export var _item_image: TextureRect
## Powerup/charm description
@export var _item_desc: Label
## Powerup/charm traits container that holds Panel nodes
@export var _item_traits: HFlowContainer
## Powerup card background
@export var _powerup_card_texture: Texture2D
## Charm card background
@export var _charm_card_texture: Texture2D

## ItemData for this button's currently associated item. Can be an Artifact or a Powerup.
var _itemdata: ItemData = null
var _stat: Constants.StatUpgrades = Constants.StatUpgrades.HEALTH
## Whether or not the button is currently being pressed
var is_pressed: bool = false

signal upgrade_chosen(itemdata: ItemData)
signal upgrade_stat_chosen(stat: Constants.StatUpgrades)
	
## Displays which Powerup or Stat this button will upgrade when clicked.
func set_upgrade(upgrade: ItemData, level_dictionary: Dictionary) -> void:
	_itemdata = upgrade
	_set_display(
			_itemdata.name, 
			_itemdata.sprite, 
			_itemdata.get_upgrade_description(level_dictionary[_itemdata.name])
	)


## Set up the text and image that appears on this button depending on what it upgrades. 
func _set_display(upgrade_name: String, texture: Texture2D, description: String):
	_item_label.text = upgrade_name
	_item_image.texture = texture
	_item_desc.text = description
	
	# Hide all traits, then later reveal associated ones
	for child in _item_traits.get_children():
		child.hide()

	if _itemdata is ArtifactData:
		$Box.texture = _charm_card_texture
		_item_label.add_theme_color_override("font_outline_color", Color.html("915C90"))
	elif _itemdata is PowerupData:
		$Box.texture = _powerup_card_texture
		_item_label.add_theme_color_override("font_outline_color", Color.html("AA3535"))
		
		for powerup_trait in _itemdata.types:
			match powerup_trait:
				Powerup.Type.ProjectileFireRate:
					$Box/Traits_Container/Fire_Rate.show()
				Powerup.Type.Haste:
					$Box/Traits_Container/Haste.show()
				Powerup.Type.AreaSize:
					$Box/Traits_Container/Area_Size.show()
				Powerup.Type.Critical:
					$Box/Traits_Container/Critical.show()


func _on_button_pressed() -> void:
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_PRESS)
	if _itemdata != null:
		upgrade_chosen.emit(_itemdata)
	else:
		upgrade_stat_chosen.emit(_stat)

func _on_button_hover() -> void:
	AudioManager.create_audio(SoundEffectSettings.SOUND_EFFECT_TYPE.UI_BUTTON_HOVER, true)
	$AnimationPlayer.play("hover")
	

func _on_button_hover_exit() -> void:
	if not is_pressed:
		$AnimationPlayer.play("unhover")


func _on_button_down() -> void:
	is_pressed = true
	$AnimationPlayer.play("press")


func _on_button_up() -> void:
	is_pressed = false
	$AnimationPlayer.play("unpress")
