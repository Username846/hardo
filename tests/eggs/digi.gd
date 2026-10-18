extends RefCounted
## DIJIMON secret: a curious player hatches the egg, then pokes the Dijivice's three little
## hardware buttons.

var tmr := 0.0
var taps := 0


func drive(bot: Node, g: Node, dt: float) -> void:
	if g.stage == 0:
		bot._drive(2, dt)
		return
	if g.locked or g.training or g.evo_t >= 0.0:
		return
	tmr += dt
	if tmr > 0.3 and taps < 8:
		tmr = 0.0
		g.press(g._dev_button_pos(taps % 3))
		taps += 1
