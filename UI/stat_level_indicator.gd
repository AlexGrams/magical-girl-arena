class_name StatLevelIndicator
extends VBoxContainer


@export var _label: Label = null
@export var icon: Texture = null

func _ready() -> void:
	$StatIcon.texture = icon

## Sets the stat level displayed on this indicator
func set_stat_value(new_value: int) -> void:
	_label.text = str(new_value)
