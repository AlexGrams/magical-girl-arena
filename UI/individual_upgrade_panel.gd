extends Panel

signal upgrade_chosen(powerup_name)
func set_powerup(title, sprite:Variant, desc):
	$VBoxContainer/Label.text = title
	$VBoxContainer/TextureRect.texture = sprite
	$VBoxContainer/Label2.text = desc

func _on_button_pressed() -> void:
	upgrade_chosen.emit($VBoxContainer/Label.text)
