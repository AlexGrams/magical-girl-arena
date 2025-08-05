extends Ability


@export var _duration: float = 10.0

var _owner: PlayerCharacterBody2D = null


func _ready() -> void:
	super()
	
	_owner = get_parent()


func _process(delta: float) -> void:
	super(delta)


func activate() -> void:
	super()
	
	var amber_ult_status: StatusAmberUlt = StatusAmberUlt.new()
	amber_ult_status.duration = _duration
	_owner.add_status(amber_ult_status)


## Change the damage of this Ability based on its owner's level.
func update_damage(_level: int) -> void:
	pass
