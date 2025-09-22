extends Bullet
## An ability that damages enemies in a large area and turns them into allies if they
## are killed by this attack. A function is called on the Enemy to convert them to allies,
## so the Enemy object isn't destroyed if killed.
##
## NOTE: Enemies usually take damage by seeing when they overlap a BulletHitbox then 
## calling take_damage on themselves. Since we may want to convert Enemies, BulletHitbox
## isn't used by this bullet, and take_damage is called by this script on overlap.

@export var hitbox: BulletHitbox = null
## Time in seconds that Enemies made allies by this attack last
@export var ally_lifetime: float = 0.0
## How much damage Enemies turned into allies do.
@export var ally_damage: float = 0.0
## Attached to Enemies that are affected by the ultimate's status after they are hit by it.
@export var status_marker: PackedScene = null
## VFX for this ability
@export var vfx: PackedScene = null

var damage: float = 0.0

## Time in seconds that the Goth Ult status lasts on Enemies.
var status_duration: float = 0.0


func set_damage(new_damage: float, _is_crit: bool = false):
	damage = new_damage


func _ready() -> void:
	var spawned_vfx: Node2D = vfx.instantiate()
	get_parent().add_child(spawned_vfx)
	spawned_vfx.position = global_position
	AudioManager.create_audio_at_location(global_position, SoundEffectSettings.SOUND_EFFECT_TYPE.ON_GOTH_ULTIMATE)


func _process(delta: float) -> void:
	# This bullet only lasts for a short time
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


# See if this attack will kill this enemy. If so, convert that enemy into an ally.
# Otherwise, deal damage to that enemy.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent() is Enemy:
		var enemy: Enemy = area.get_parent()
		if not enemy.is_ally:
			enemy.take_damage(damage, collider)
			if is_multiplayer_authority():
				enemy.apply_status_goth_ult(status_duration, ally_lifetime, ally_damage)
				_spawn_marker.rpc(enemy.get_path())
	elif area.get_parent().has_method("take_damage") and is_multiplayer_authority():
		area.get_parent().take_damage(damage)


## Create a marker indicating that this enemy is under the effect of this status.
@rpc("authority", "call_local")
func _spawn_marker(enemy_path: NodePath) -> void:
	var enemy: Enemy = get_node(enemy_path)
	if enemy == null:
		return
	
	var spawned_status_marker: StatusGothUlt = status_marker.instantiate()
	enemy.add_child(spawned_status_marker, true)
	spawned_status_marker.position = Vector2.ZERO
	spawned_status_marker.destroy_after_duration(status_duration)


# Set up other properties for this bullet
func setup_bullet(is_owned_by_player: bool, data: Array) -> void:
	if (len(data) < 1 
		or typeof(data[0]) != TYPE_FLOAT	# Status duration
	):
		push_error("Malformed data")
		return
	
	_is_owned_by_player = is_owned_by_player
	status_duration = data[0]
