extends Powerup
## A boss powerup that combines the Revolving and Raindrop powerups.


## Path to Boss Revolving powerup
@export var _revolving_powerup_scene: String = ""
## Path to Boss Raindrop powerup
@export var _raindrop_powerup_scene: String = ""

var _revolving_powerup: Powerup = null
var _raindrop_powerup: Powerup = null


func _ready() -> void:
	set_process(false)
	
	if multiplayer.is_server():
		# Instantiate the Revolving and Raindrop powerups and make them children of this powerup.
		_revolving_powerup = load(_revolving_powerup_scene).instantiate()
		_raindrop_powerup = load(_raindrop_powerup_scene).instantiate()
		_revolving_powerup.set_authority(get_multiplayer_authority())
		_raindrop_powerup.set_authority(get_multiplayer_authority())
		add_child(_revolving_powerup)
		add_child(_raindrop_powerup)


func _process(_delta: float) -> void:
	pass


func activate_powerup():
	is_on = true
	_revolving_powerup.activate_powerup_for_enemy()
	_raindrop_powerup.activate_powerup_for_enemy()


# For when adding this powerup to an Enemy when it is usually added to a Player.
func activate_powerup_for_enemy():
	_is_owned_by_player = false
	activate_powerup()


func deactivate_powerup():
	is_on = false
	_revolving_powerup.deactivate_powerup()
	_raindrop_powerup.deactivate_powerup()
