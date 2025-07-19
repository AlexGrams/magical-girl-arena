extends Node2D


func set_angry():
	$Bee.self_modulate = Color.RED
	$Mouth.rotation = deg_to_rad(180)
	await get_tree().create_timer(1.0).timeout
	set_happy()

func set_happy():
	$Bee.self_modulate = Color.WHITE
	$Mouth.rotation = deg_to_rad(0)


func set_opacity():
	$Wing2.self_modulate.a = GameState.other_players_bullet_opacity
	$Bee.self_modulate.a = GameState.other_players_bullet_opacity
	$Wing1.self_modulate.a = GameState.other_players_bullet_opacity
	$Mouth.self_modulate.a = GameState.other_players_bullet_opacity
