extends Control
## Used for inputting written feedback from users and sending it to our PlayFab database using Telemetry events.

## We are limited with how big of a message we can send to the PlayFab servers using telemetetry events (10kB).
## I believe that this limit is large if the message is just text, but this is to ensure that it is never reached.
## More: https://learn.microsoft.com/en-us/gaming/playfab/data-analytics/legacy/insights/best-practices 
const MAX_CHARACTERS = 8000

@export var _text_box: TextEdit = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# TODO: Limit length of text that can be entered into the text box.
	pass


func _on_button_submit_down() -> void:
	Analytics.send_feedback(_text_box.text)
	_text_box.text = ""
	hide()
