extends Node2D


# Delete this EXP orb on all clients. Only call on the server.
@rpc("any_peer", "call_local")
func destroy() -> void:
	self.queue_free()
