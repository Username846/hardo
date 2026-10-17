extends RefCounted
## Autopilot for KNEAD FOR SPEED: picks a look in the garage, drives the clearest lane,
## fires nitro on open road and shifts in the green.

var tmr := 0.0
var lane := 0.0
var last_phase := ""


func drive(bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	if g.phase != last_phase:
		last_phase = g.phase
		tmr = 0.0
	match g.phase:
		"garage":
			if not g.locked and tmr > 2.5:
				tmr = 0.0
				bot._btn("g_blue")
				bot._btn("v_stars")
				bot._btn("go")
		"race", "circuit", "count", "grid":
			_steer(g)
		"drag":
			if g.rpm >= 0.82 and g.gear < 5:
				g._shift()


func _steer(g: Node) -> void:
	# how far ahead each lane is clear (traffic and rivals both count)
	var free := {}
	for lx in g.LANES:
		free[lx] = 99999.0
	for c in g.traffic + g.rivals:
		var dz: float = g._dz(c)
		if dz < -150.0:
			continue
		for lx in g.LANES:
			if absf(float(c.x) - lx) < 0.5:
				free[lx] = minf(free[lx], dz)
	if free.get(lane, 0.0) < 2600.0:
		var best: float = lane
		for lx in g.LANES:
			if free[lx] > free[best] + 1.0 or (free[lx] == free[best] and absf(lx - g.player_x) < absf(best - g.player_x)):
				best = lx
		lane = best
	g.steer_x = 640.0 + lane * g.X_PX
	if g.phase in ["race", "circuit"] and g.nitro >= 0.34 and g.nitro_t <= 0.0 and free.get(lane, 0.0) > 5000.0:
		g._nitro()


func dbg(g: Node) -> String:
	return "phase=%s mode=%s z=%.0f x=%.2f speed=%.0f nitro=%.2f lap=%d place=%d gear=%d rpm=%.2f locked=%s" % [
		g.phase, g.mode, g.player_z, g.player_x, g.speed, g.nitro, g.lap, g._place(), g.gear, g.rpm, g.locked]
