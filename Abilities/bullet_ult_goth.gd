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


func set_damage(new_damage: float):
	damage = new_damage


func _ready() -> void:
	var spawned_vfx: Node2D = vfx.instantiate()
	get_parent().add_child(spawned_vfx)
	spawned_vfx.position = global_position


func _process(delta: float) -> void:
	# This bullet only lasts for a short time
	death_timer += delta
	if death_timer >= lifetime and is_multiplayer_authority():
		queue_free()


# See if this attack will kill this enemy. If so, convert that enemy into an ally.
# Otherwise, deal damage to that enemy.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_multiplayer_authority():
		return
	
	var enemy: Enemy = area.get_parent()
	if not enemy.is_ally:
		if enemy.health - damage > 0.0:
			enemy.take_damage(damage)
		else:
			# This attack kills this enemy, so make it an ally
			enemy.make_ally.rpc(ally_lifetime, ally_damage)


# Set up other properties for this bullet
func setup_bullet(_is_owned_by_player: bool, _data: Array) -> void:
	pass
