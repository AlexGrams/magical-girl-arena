extends Playground
## Removes pieces from the map depending on the time.


## Time in seconds between a piece of the map falling.
@export var _fall_interval: float = 5.0
@export var _pieces_outer_diamonds: Array[DesertMapPiece] = []
@export var _pieces_squares: Array[DesertMapPiece] = []
@export var _pieces_corners: Array[DesertMapPiece] = []
@export var _pieces_sides: Array[DesertMapPiece] = []
@export var _pieces_center: Array[DesertMapPiece] = []

var _fall_timer: float = 0.0
var _pieces_phase_1: Array[DesertMapPiece] = []
var _pieces_phase_2: Array[DesertMapPiece] = []


func _ready() -> void:
	super()
	
	if not is_multiplayer_authority():
		return
	
	_pieces_phase_1.append_array(_pieces_outer_diamonds)
	_pieces_phase_1.append_array(_pieces_squares)
	
	_pieces_phase_2.append_array(_pieces_outer_diamonds)
	_pieces_phase_2.append_array(_pieces_squares)
	_pieces_phase_2.append_array(_pieces_corners)
	_pieces_phase_2.append_array(_pieces_sides)
	_pieces_phase_2.append_array(_pieces_center)


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	super(delta)
	
	# Temporarily remove a piece of the map every few seconds.
	_fall_timer += delta
	if _fall_timer > _fall_interval:
		if GameState.time > 12 * 60.0:
			# 15:00 - 12:00: Map doesn't fall 
			pass
		elif GameState.time > 8 * 60.0:
			# 12:00 - 8:00: Squares and diamonds
			if len(_pieces_phase_1) > 0:
				var i: int = randi_range(0, len(_pieces_phase_1) - 1)
				_pieces_phase_1[i].initiate_falling()
				_pieces_phase_1[i].returned.connect(_append_to_pieces_phase_1)
				_pieces_phase_1.remove_at(i)
		elif GameState.time > 3 * 60.0:
			# 8:00 - 3:00: Any piece
			if len(_pieces_phase_2) > 0:
				var i: int = randi_range(0, len(_pieces_phase_2) - 1)
				_pieces_phase_2[i].initiate_falling()
				_pieces_phase_2[i].returned.connect(_append_to_pieces_phase_2)
				_pieces_phase_2.remove_at(i)
		else:
			# 3:00 - 0:00: Every piece but the center
			pass
		
		_fall_timer = 0


func _append_to_pieces_phase_1(piece: DesertMapPiece) -> void:
	_pieces_phase_1.append(piece)
	piece.returned.disconnect(_append_to_pieces_phase_1)


func _append_to_pieces_phase_2(piece: DesertMapPiece) -> void:
	_pieces_phase_2.append(piece)
	piece.returned.disconnect(_append_to_pieces_phase_2)
