extends Playground
## Removes pieces from the map depending on the time.


@export var _pieces_outer_diamonds: Array[DesertMapPiece] = []
@export var _pieces_squares: Array[DesertMapPiece] = []
@export var _pieces_corners: Array[DesertMapPiece] = []
@export var _pieces_sides: Array[DesertMapPiece] = []
@export var _pieces_center: Array[DesertMapPiece] = []


func _ready() -> void:
	super()


func _process(delta: float) -> void:
	super(delta)
	
	if GameState.time > 12 * 60.0:
		# 15:00 - 12:00: Map doesn't fall 
		pass
	elif GameState.time > 8 * 60.0:
		# 12:00 - 8:00: Squares and diamonds
		pass
	elif GameState.time > 3 * 60.0:
		# 8:00 - 3:00: Any piece
		pass
	else:
		# 3:00 - 0:00: Every piece but the center
		pass
