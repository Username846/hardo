extends RefCounted
## FORTNIGHT secret: poke your own player three times quickly to emote (everyone dances).

var pokes := 0
var tmr := 0.0


func drive(bot: Node, g: Node, dt: float) -> void:
	if g.phase == "fight" and g.fight_t > 9.0 and pokes < 3 and not g.locked:
		tmr += dt
		if tmr > 0.15:
			tmr = 0.0
			pokes += 1
			g.press(g.ME + Vector2(4, -12))
		return
	bot._drive(5, dt)
