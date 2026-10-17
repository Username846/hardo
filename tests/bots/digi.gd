extends RefCounted
## Autopilot for DIJIMON: hatch, keep the meters up, clean the poop, hit the training
## bar, feed it the name, pick a Chumbo.

var tmr := 0.0


func drive(bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	if g.choice and not g.locked:
		bot._btn("c1")
		return
	if g.training:
		if absf(g._marker() - g.train_zone) < g.train_w * 0.3:
			g.press(Vector2(640, 300))
		return
	if g.locked or g.busy:
		return
	if g.stage == 0:
		if tmr > 0.15:
			tmr = 0.0
			g.press(g.CENTER)
		return
	if tmr < 0.3:
		return
	tmr = 0.0
	if g.stage >= 5:
		bot._btn("feed")
		return
	if not g.poops.is_empty():
		bot._btn("clean")
		return
	var m: Array = g.meters
	var lo := 0
	for k in 3:
		if m[k] < m[lo]:
			lo = k
	if m[lo] < 0.99:
		bot._btn(["feed", "train", "pet"][lo])


func dbg(g: Node) -> String:
	return "stage=%d locked=%s busy=%s meters=%s poops=%d training=%s evo=%.1f age=%d" % [g.stage, g.locked, g.busy, g.meters, g.poops.size(), g.training, g.evo_t, int(g.age)]
