extends RefCounted
## Autopilot for CALL OF BIRTHDAY (duty.gd): aims perfectly, opens care packages, tries the
## "mission failed" joke and hits Grandma once so those paths run too.

var tmr := 0.0
var misses := 0
var grandma_done := false


func drive(_bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	if g.locked or not g._playing():
		return
	if not g.care.is_empty() and g.care.landed:
		g.press(g.care.pos + Vector2(0, -30))
		return
	if tmr < 0.14:
		return
	tmr = 0.0
	if g.phase == "m1" and misses < 6:
		misses += 1
		_shoot(g, Vector2(640, 40))
		return
	# DUTY_CLOSE=1: let the guests walk up close first (for screenshots)
	var close := OS.get_environment("DUTY_CLOSE") != ""
	var zs: Array = g.zombies.filter(func(z): return z.state == "walk" and (not close or z.z > 0.6))
	zs.sort_custom(func(a, b): return a.z > b.z)
	if zs.size() > 0:
		_shoot(g, g._zombie_rect(zs[0]).get_center())
		return
	for d in g.drones:
		if d.state != "pop":
			_shoot(g, d.pos)
			return
	for tg in g.targets:
		if (tg.state == "rise" or tg.state == "up") and tg.rise > 0.5:
			if tg.kind == "grandma":
				if grandma_done:
					continue
				grandma_done = true
			_shoot(g, g._target_rect(tg).get_center())
			return


func _shoot(g: Node, p: Vector2) -> void:
	g.mouse = p
	g.press(p)


func dbg(g: Node) -> String:
	return "phase=%s round=%d downed=%d/%d ammo=%d xp=%d rank=%d zombies=%d targets=%d drones=%d slices=%d" % [
		g.phase, g.round_i, g.downed, g.goal, g.ammo, g.xp, g.rank, g.zombies.size(), g.targets.size(), g.drones.size(), g.slices]
