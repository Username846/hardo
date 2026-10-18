extends RefCounted
## Card Checkpoint secret: squeak the bone on the dog's card three times and the dog comes for it.

var taps := 0
var wait_t := 0.0


func drive(bot: Node, g: Node, dt: float) -> void:
	if g.i < 0 or g.locked:
		return
	if g.i < g.cards.size() and String(g.cards[g.i].pic) == "bone":
		# don't stamp this one yet: give the bone a squeeze
		if g.busy or g.card_off.length() > 4.0:
			return
		wait_t += dt
		if wait_t > 0.35 and taps < 3:
			wait_t = 0.0
			taps += 1
			g.press(g.CARD.position + Vector2(g.CARD.size.x * 0.5, 70))
		return
	bot._drive(3, dt)
