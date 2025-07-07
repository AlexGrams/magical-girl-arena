class_name LobbyButton
extends Node


@export var username_label: Label
@export var playercount_label: Label
@export var texture_box: TextureRect
@export var ping_label: Label

var original_scale:Vector2


func _ready() -> void:
	if username_label == null:
		push_warning("Username_label has not been assigned")
	if playercount_label == null:
		push_warning("Playercount_label has not been assigned")
	if texture_box == null:
		push_warning("Texture_box has not been assigned")
	else:
		original_scale = texture_box.scale

func set_host_name(host_name:String):
	username_label.text = host_name


func set_playercount(count:String):
	playercount_label.text = count + "/" + str(GameState.MAX_PLAYERS) + " players"


func set_ping(other_location: String) -> void:
	var ping = Steam.estimatePingTimeFromLocalHost(PackedByteArray(str_to_var(other_location)))
	if ping < 0:
		ping = "Unknown"
	ping_label.text = "Ping: " + str(ping)


func _on_mouse_entered():
	texture_box.scale = original_scale * 1.05


func _on_mouse_exited():
	texture_box.scale = original_scale
