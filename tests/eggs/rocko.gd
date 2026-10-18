extends RefCounted
## Secret test for the Rocko game: close the phone, pet Rocko, then once the chase is going,
## poke Rocko four times in a row (dodging the rest of the time).

var tmr := 0.0
var pokes := 0


func drive(bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	match g.phase:
		"phone":
			if not g.locked:
				g.press(g._x_rect().get_center())
		"pets":
			if not g.locked and tmr > 0.35:
				tmr = 0.0
				g.press(g._cat_rect().get_center())
		"chase", "chase_intro":
			if g.phase == "chase" and g.dist > 10.0 and pokes < 4 and g.rocko_x > -100.0:
				if tmr > 0.3:
					tmr = 0.0
					pokes += 1
					g.press(Vector2(g.rocko_x - 10.0, g.rocko_y - 100.0))
				return
			bot._dodge()
