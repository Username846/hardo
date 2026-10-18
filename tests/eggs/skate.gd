extends RefCounted
## TONY HONK secret: a player who just rides along without tapping for a while.


func drive(_bot: Node, g: Node, _dt: float) -> void:
	# hands off: let the board roll
	if g.pressing:
		g.release(Vector2.ZERO)
