extends CharacterBody2D

@export var level_exp_needed:Array
@export var level_shoot_intervals:Array
@export var speed = 400
@onready var bullet_scene = preload("res://bullet.tscn")
var shoot_timer = 0
var shoot_interval = 1
var experience = 0
var health = 100
var level = 1

signal took_damage(health)
signal gained_experience(experience, level)

func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed
	
func _process(delta: float) -> void:
	var direction = get_global_mouse_position() - $Sprite2D.global_position
	var direction_normal = direction.normalized()
	$Line2D.points = [direction_normal*100, Vector2.ZERO]
	
	shoot_timer += delta
	if shoot_timer > shoot_interval:
		var bullet = bullet_scene.instantiate()
		bullet.direction = direction_normal
		bullet.position = position + (direction_normal * 100)
		get_tree().root.add_child(bullet)
		shoot_timer = 0

func _physics_process(delta):
	get_input()
	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(2): #If Enemy
		health -= 10
		took_damage.emit(health)
		$AnimationPlayer.play("took_damage")
		if health <= 0:
			get_tree().paused = true
			$".".hide()
	elif area.get_collision_layer_value(3): #If EXP Orb
		experience += 1
		if level < 6 and experience >= level_exp_needed[level-1]:
			experience = 0
			level += 1
			shoot_interval = level_shoot_intervals[level]
			for child in get_children():
				if child is Powerup:
					child.level_up()
		gained_experience.emit(experience, level)
		area.get_parent().queue_free()
