extends RefCounted
## R.E.P.O. secret: poke the Peeper (the big eye on the library ceiling) five times.

var tmr := 0.0
var pokes := 0


func drive(bot: Node, g: Node, dt: float) -> void:
	# haul like normal in between
	bot._drive(8, dt)
	if g.shades > 0.0 or not g.playing or g.locked or g.phase != "run1" or g.deposited < 1:
		return
	tmr += dt
	if tmr < 0.35:
		return
	tmr = 0.0
	pokes += 1
	g.press(g.PEEPER + Vector2(randf_range(-10, 10), randf_range(-8, 8)))
