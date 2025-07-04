class_name StatusTempHealth
extends Status
## Health that goes away after a duration. When the owner takes damages, this value is decremented
## before their actual health is.


## How much temp HP is remaining for this segment.
var value: int = 0


func get_status_name() -> String:
	return "TempHealth"
