class_name LobbyButton
extends Button


@export var username_label: Label
@export var playercount_label: Label
@export var texture_box: TextureRect
@export var ping_label: Label
@export var host_label: Label

var original_scale: Vector2


func _ready() -> void:
	if username_label == null:
		push_warning("Username_label has not been assigned")
	if playercount_label == null:
		push_warning("Playercount_label has not been assigned")
	if texture_box == null:
		push_warning("Texture_box has not been assigned")
	else:
		original_scale = texture_box.scale


func set_lobby_button_disabled(value: bool) -> void:
	disabled = value
	if disabled:
		texture_box.self_modulate = Color.DIM_GRAY
		host_label.self_modulate = Color.DIM_GRAY
		username_label.self_modulate = Color.DIM_GRAY
		playercount_label.self_modulate = Color.DIM_GRAY
		ping_label.self_modulate = Color.DIM_GRAY
	else:
		texture_box.self_modulate = Color.WHITE
		host_label.self_modulate = Color.WHITE
		username_label.self_modulate = Color.WHITE
		playercount_label.self_modulate = Color.WHITE
		ping_label.self_modulate = Color.WHITE


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
	if not disabled:
		texture_box.scale = original_scale * 1.05


func _on_mouse_exited():
	if not disabled:
		texture_box.scale = original_scale
