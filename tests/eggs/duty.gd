extends RefCounted
## CALL OF BIRTHDAY secret: shoot the three teddy bears hiding in the yard.

var shot := 0
var tmr := 0.0


func drive(bot: Node, g: Node, dt: float) -> void:
	if g.locked or not g._playing():
		return
	if shot < g.TEDDIES.size():
		tmr += dt
		if tmr > 0.4 and g.reloading <= 0.0:
			tmr = 0.0
			var p: Vector2 = g.TEDDIES[shot][0] + Vector2(0, -6)
			g.mouse = p
			g.press(p)
			shot += 1
		return
	bot._drive(4, dt)
