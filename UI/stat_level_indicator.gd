class_name StatLevelIndicator
extends VBoxContainer


@export var _label: Label = null


## Sets the stat level displayed on this indicator
func set_stat_value(new_value: int) -> void:
	_label.text = str(new_value)
