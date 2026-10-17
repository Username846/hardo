extends RefCounted
## Autopilot for TONY HONK'S PRO SKATER 2: pops off every ramp, ollies the cake and onto the
## rails, flips (and sometimes grabs) whenever there is air to spare.

var hold := 0.0
var flips := 0
var grabs := 0
var bails := 0
var was_bail := false
var prev_state := ""
var prev_flip := 0.0


func drive(_bot: Node, g: Node, dt: float) -> void:
	if g.state == "bail" and not was_bail:
		bails += 1
		if OS.get_environment("SKATE_DEBUG") != "":
			print("BAIL at ", int(fposmod(g.x, g.LOOP)), " prev=", prev_state, " flip=", prev_flip, " y=", int(g.y))
	was_bail = g.state == "bail"
	prev_state = g.state
	prev_flip = g.flip_t
	if not g.skating or g.locked:
		if g.pressing:
			g.release(Vector2.ZERO)
		hold = 0.0
		return
	if hold > 0.0:
		hold -= dt
		if hold <= 0.0:
			g.release(Vector2.ZERO)
		return
	var xm: float = fposmod(g.x, g.LOOP)
	match String(g.state):
		"ground":
			if g._on_ramp():
				if not g.lip_pop:
					_tap(g, 0.03)
				return
			for f: Dictionary in g.PARK:
				var ahead: float = float(f.x) - xm
				if f.k == "cake" and ahead > 80.0 and ahead < 190.0:
					_tap(g, 0.03)
					return
				if (f.k == "rail" or f.k == "candle") and ahead > 10.0 and ahead < 150.0:
					_tap(g, 0.03)
					return
		"air":
			var land: float = g._time_to_land()
			if g.flip_t <= 0.0 and not g.grab:
				if land > 1.0 and (flips + grabs) % 3 == 2:
					grabs += 1
					_tap(g, 0.45)
				elif land > 0.55:
					flips += 1
					_tap(g, 0.03)
		"grind":
			var r: Dictionary = g.rail
			if r.k == "candle" and float(r.x) + float(r.w) - xm < 70.0:
				_tap(g, 0.03)


func _tap(g: Node, sec: float) -> void:
	g.press(Vector2.ZERO)
	hold = sec


func dbg(g: Node) -> String:
	return "phase=%s state=%s x=%d score=%d goals=%d/%d left=%.1f flips=%d grabs=%d bails=%d" % [
		g.phase, g.state, int(g.x), g.score, g._goals_done(), g.goals.size(), g.time_left, flips, grabs, bails]
