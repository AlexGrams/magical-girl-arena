class_name PowerupInformationPanel
extends Panel


@export var _powerup_panels: Array[IndividualInformationPanel] = []
@export var _charm_panels: Array[IndividualInformationPanel] = []

var _powerup_panel_index: int = 0
var _charm_panel_index: int = 0
## Maps the String name of an Item to the IndividualInformationPanel that displays its information.
var _itemdata_name_to_information_panel: Dictionary = {}


func _ready() -> void:
	for panel: Control in _powerup_panels:
		panel.hide()
	
	for panel: Control in _charm_panels:
		panel.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_powerup_information"):
		show()
	elif event.is_action_released("show_powerup_information"):
		hide()


func add_powerup_information(data: ItemData) -> void:
	if _powerup_panel_index >= len(_powerup_panels):
		return
	
	_powerup_panels[_powerup_panel_index].set_upgrade(data)
	_powerup_panels[_powerup_panel_index].show()
	_itemdata_name_to_information_panel[data.name] = _powerup_panels[_powerup_panel_index]
	_powerup_panel_index += 1


func add_charm_information(data: ItemData) -> void:
	if _charm_panel_index >= len(_charm_panels):
		return
	
	_charm_panels[_charm_panel_index].set_upgrade(data)
	_charm_panels[_charm_panel_index].show()
	_itemdata_name_to_information_panel[data.name] = _charm_panels[_charm_panel_index]
	_charm_panel_index += 1


## Update an existing information panel.
func update_information_panel(data: ItemData) -> void:
	if data.name not in _itemdata_name_to_information_panel:
		return
	
	_itemdata_name_to_information_panel[data.name].set_upgrade(data)
