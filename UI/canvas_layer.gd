extends CanvasLayer

@export var _game_over_screen: Control = null
var textures:Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textures.append($Abilities/Panel/TextureRect)
	textures.append($Abilities/Panel2/TextureRect)
	textures.append($Abilities/Panel3/TextureRect)
	textures.append($Abilities/Panel4/TextureRect)
	textures.append($Abilities/Panel5/TextureRect)
	
	$ExperienceBar.value = 0.0
	
	# Game over screen visibility
	GameState.game_over.connect(func():
		_game_over_screen.show()
	)
	_game_over_screen.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_character_body_2d_gained_experience(experience: float, level: int) -> void:
	$ExperienceBar.value = experience
	$LevelLabel.text = "Level: " + str(level)


func _on_character_body_2d_took_damage(health:int, health_max:int) -> void:
	$HealthBar/HealthLabel.text = str(health) + "/" + str(health_max)
	$HealthBar.value = float(health) / health_max


func _on_powerup_picked_up_powerup(sprite: Variant) -> void:
	for i in range(0, 5):
		if textures[i].texture == null:
			textures[i].texture = sprite
			return


func _on_retry_button_down() -> void:
	print("Go again")


func _on_lobby_button_down() -> void:
	print("Go to lobby")


func _on_quit_button_down() -> void:
	print("Go to main menu")
