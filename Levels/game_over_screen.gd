class_name GameOverScreen
extends Control


## Main display text
@export var text: Label = null


## Set the Game Over screen appearance based on if the player has won or not.
func set_up(has_won_game: bool) -> void:
	if has_won_game:
		text.text = "You won!"
	show()
