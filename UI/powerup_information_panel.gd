class_name PowerupInformationPanel
extends Panel


@export var _powerup_panels: Array[IndividualInformationPanel] = []
@export var _charm_panels: Array[IndividualInformationPanel] = []

var _powerup_panel_index: int = 0
var _charm_panel_index: int = 0


func _ready() -> void:
	for panel: Control in _powerup_panels:
		panel.hide()
	
	for panel: Control in _charm_panels:
		panel.hide()


func add_powerup_information(data: ItemData) -> void:
	if _powerup_panel_index >= len(_powerup_panels):
		return
	
	_powerup_panels[_powerup_panel_index].set_upgrade(data)
	_powerup_panels[_powerup_panel_index].show()
	_powerup_panel_index += 1


func add_charm_information(data: ItemData) -> void:
	if _charm_panel_index >= len(_charm_panels):
		return
	
	_charm_panels[_charm_panel_index].set_upgrade(data)
	_charm_panels[_charm_panel_index].show()
	_charm_panel_index += 1
