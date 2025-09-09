class_name IndividualInformationPanel
extends Control

## Powerup/charm name
@export var _item_label: Label
## Powerup/charm image
@export var _item_image: TextureRect
## Powerup/charm description
@export var _item_desc: Label
## Powerup/charm traits container that holds Panel nodes
@export var _item_traits: HFlowContainer
## Card border
@export var _card_border: TextureRect
## Powerup card background
@export var _powerup_card_texture: Texture2D
## Charm card background
@export var _charm_card_texture: Texture2D

## ItemData for this button's currently associated item. Can be an Artifact or a Powerup.
var _itemdata: ItemData = null
	
## Displays which Powerup or Stat this button will upgrade when clicked.
func set_upgrade(upgrade: ItemData) -> void:
	_itemdata = upgrade
	
	# Special hack logic for displaying description if item is the critical artifact since the
	# same artifact can have multiple descriptions.
	_set_display(
			_itemdata.name, 
			_itemdata.sprite, 
			_itemdata.get_upgrade_description() if not _itemdata is PowerupCriticalArtifactData else _itemdata._description
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
		var charm_accent_color:Color = Color.html("915C90")
		$Box.texture = _charm_card_texture
		_card_border.self_modulate = charm_accent_color
		_item_label.add_theme_color_override("font_outline_color", charm_accent_color)
	elif _itemdata is PowerupData:
		var powerup_accent_color:Color = Color.html("AA3535")
		$Box.texture = _powerup_card_texture
		_card_border.self_modulate = powerup_accent_color
		_item_label.add_theme_color_override("font_outline_color", powerup_accent_color)
		
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
