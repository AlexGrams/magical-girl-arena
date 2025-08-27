extends Powerup
## A ball that can be kicked around by players. Damages Enemies that it touches, growing bigger
## with each kill until it explodes and returns to its starting size.


## Path to the Bullet-derived bullet scene.
@export var _bullet_scene := ""
## Path to the PowerupData resource file for this Powerup.
@export var _powerup_data_file_path: String = ""


func _ready() -> void:
	powerup_name = load(_powerup_data_file_path).name


func _process(delta: float) -> void:
	pass


func activate_powerup():
	is_on = true


func deactivate_powerup():
	is_on = false


func level_up():
	current_level += 1


func boost() -> void:
	push_warning("Ball has no boost functionality")
	pass


func unboost() -> void:
	pass
