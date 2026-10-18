extends RefCounted
## Autopilot for CALL OF BIRTHDAY (duty.gd): aims perfectly, opens care packages, tries the
## "mission failed" joke and hits Grandma once so those paths run too. At the front it pulls
## friends back to the trench before the shells land.

var tmr := 0.0
var misses := 0
var grandma_done := false


func drive(_bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	if g.phase == "front" and not g.locked:
		_front(g)
		return
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


## At the front: pull back whoever has a shell coming down on them soonest (like a person,
## one tap every so often, and only once the warning shadow shows).
func _front(g: Node) -> void:
	if tmr < 0.35:
		return
	var best = null
	var best_left := 99.0
	for sh in g.shells:
		if sh.boom or sh.t < 0.0:
			continue
		for f in g.squad:
			if f.state == "pinned" and g._field_feet(f.x, f.z).distance_to(g._field_feet(sh.x, sh.z)) < g.SHELL_R and sh.warn - sh.t < best_left:
				best = f
				best_left = sh.warn - sh.t
	if best != null:
		tmr = 0.0
		var c: Vector2 = g._friend_rect(best).get_center()
		g.mouse = c
		g.press(c)


func _shoot(g: Node, p: Vector2) -> void:
	g.mouse = p
	g.press(p)


func dbg(g: Node) -> String:
	var lost: int = g.squad.filter(func(f): return f.state == "lost").size()
	return "phase=%s day=%d downed=%d/%d ammo=%d xp=%d rank=%d lost=%d shells=%d targets=%d drones=%d slices=%d" % [
		g.phase, g.day, g.downed, g.goal, g.ammo, g.xp, g.rank, lost, g.shells.size(), g.targets.size(), g.drones.size(), g.slices]
