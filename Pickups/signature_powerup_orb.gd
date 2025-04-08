class_name SignaturePowerupOrb
extends EXPOrb


## Size in pixels that this powerup image should be.
const _size: Vector2 = Vector2(100, 100)

## Changes depending on what Powerup this pickup grants.
@export var sprite: Sprite2D = null

var _pickup_powerup_data: PowerupData = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Destroys this object and gives a Powerup upgrade if possible.
func _on_area_2d_area_entered(area: Area2D) -> void:
	var other: Node2D = area.get_parent()
	if (uncollected 
		and multiplayer.get_unique_id() == area.get_multiplayer_authority() 
		and other is PlayerCharacterBody2D
	):
		# Check if player can pick up this upgrade
		var player_character: PlayerCharacterBody2D = other 
		var has_upgradable_powerup = false
		
		# Check if they have the Powerup already and it isn't max level and signature
		for powerup: Powerup in player_character.powerups:
			if powerup.powerup_name == _pickup_powerup_data.name:
				if powerup.current_level == powerup.max_level and powerup.is_signature:
					# Player has the powerup already, it is max level, and is signature, so
					# they can't get this pickup because it wouldn't give them anything.
					return
				has_upgradable_powerup = true
				break
		
		# Alternatively, they can pick this up if they don't have the Powerup already and they are
		# not maxed out on Powerups.
		if has_upgradable_powerup or len(player_character.powerups) < PlayerCharacterBody2D.MAX_POWERUPS:
			player_character.upgrade_or_grant_powerup(_pickup_powerup_data, true)
			uncollected = false
			destroy.rpc_id(1) 


## Does nothing to prevent this orb type from gravitating. Should not be called.
@rpc("any_peer", "call_local")
func set_player(_new_player: NodePath) -> void:
	pass


## Set what Powerup is acquired if this orb is picked up.
@rpc("authority", "call_local")
func set_powerup(powerup_data_path: String) -> void:
	_pickup_powerup_data = load(powerup_data_path)
	sprite.texture = _pickup_powerup_data.sprite
	
	# Manually rescale the sprite while maintaining its aspect ratio depending on the pixel size 
	# of the Powerup image. This is so that the pickup isn't too big or small depending on the size
	# of its texture.
	var texture_size: Vector2 = sprite.texture.get_size()
	var largest_dimension_length: float = max(texture_size.x, texture_size.y)
	sprite.scale = ((_size * Vector2(texture_size.x / largest_dimension_length, texture_size.y / largest_dimension_length)) 
					/ texture_size)
