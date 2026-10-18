extends RefCounted
## POKeMANS secret: in the overworld, headbutt (tap) the same tree three times.

var tmr := 0.0
var taps := 0


func drive(bot: Node, g: Node, dt: float) -> void:
	if g.gold_ball:
		return
	if g.mode != "walk" or g.locked:
		# battles: just play them normally
		bot._drive(7, dt)
		return
	tmr += dt
	if tmr < 0.6 + (0.0 if taps == 0 else 0.0) or (taps == 0 and tmr < 1.0):
		return
	tmr = 0.45
	taps += 1
	g.press(g._tree(2) + Vector2(randf_range(-12, 12), randf_range(-12, 12)))
