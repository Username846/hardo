extends RefCounted
## Autopilot for R.E.P.O.: grab the nearest valuable, carry it to the truck, bonk gnomes
## that get close, extract, pick an upgrade, then haul everything in run two.

var tmr := 0.0
var stuck := 0.0
var last_key := ""
var menu_t := 0.0
var poked := false
var duck_was := "cute"


func drive(bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	if g.duck.state != duck_was:
		duck_was = g.duck.state
		print("REPO duck ", duck_was, " stun=", g.stun_t, " carried=", "" if g.carried.is_empty() else g.carried.name)
	# give menus a moment on screen (like a person reading them), then press
	if not g.get_button("extract").is_empty() or not g.get_button("up1").is_empty():
		menu_t += dt
		if menu_t > 1.0:
			menu_t = 0.0
			if not bot._btn("extract"):
				bot._btn("up1")
		return
	if not g.playing or g.locked:
		return
	# poke the duck once (to check the chase), then never again
	if not poked and g.run == 1 and g.deposited == 1 and g.duck.state == "cute":
		poked = true
		g.press(g.duck.pos)
		return
	# bonk gnomes that are about to chip the thing we carry (with a real tap)
	if not g.carried.is_empty():
		for gn in g.gnomes:
			if gn.stun <= 0.0 and gn.pos.distance_to(g.carried.pos) < 90.0 and gn.pos.distance_to(g.duck.pos) > 50.0:
				g.press(gn.pos)
				return
	if tmr < 0.4:
		return
	tmr = 0.0
	var key := ""
	if g.carried.is_empty():
		var best = null
		for it in g.items:
			if it.state == "free" and (best == null or g.bot_pos.distance_to(it.pos) < g.bot_pos.distance_to(best.pos)):
				best = it
		if best == null:
			return
		key = "get " + String(best.name)
		if g.path.is_empty() or g.want_grab != best:
			if best.pos.distance_to(g.duck.pos) > 50.0:
				g.press(best.pos)
			else:
				g.want_grab = best
				g._walk_to(best.pos)
	else:
		key = "carry " + String(g.carried.name)
		if g.path.is_empty():
			g.press(g.ZONE if g.ZONE.distance_to(g.duck.pos) > 50.0 else g.ZONE + Vector2(60, 0))
	# safety: if one job takes too long, hop closer
	if key == last_key:
		stuck += 0.4
	else:
		stuck = 0.0
		last_key = key
	if stuck > 25.0:
		stuck = 0.0
		g.path.clear()
		g.bot_pos = g._clamp_in_room(g.ZONE + Vector2(0, -60) if not g.carried.is_empty() else g.want_grab.pos + Vector2(40, 0))


func dbg(g: Node) -> String:
	return "phase=%s run=%d haul=%d quota=%d dep=%d carried=%s bot=%s path=%d" % [g.phase, g.run, g.haul, g.quota, g.deposited, "" if g.carried.is_empty() else g.carried.name, g.bot_pos, g.path.size()]
