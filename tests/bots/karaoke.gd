extends RefCounted
## Autopilot for MIKAKE KARAOKE: tap when a note lands, then blow out the candles.

var tmr := 0.0


func drive(_bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	if g.phase == "cute" or g.phase == "dark":
		var now: float = Audio.song_pos
		for k in g.chart.size():
			if not g.hits.has(k) and absf(float(g.chart[k][0]) - now) < 0.05:
				g.press(Vector2(640, 360))
				break
	elif g.phase == "candles" and tmr > 0.4 and not g.locked:
		tmr = 0.0
		for c in g.candles:
			if c.lit:
				g.press(Vector2(c.x, 400))
				break


func dbg(g: Node) -> String:
	return "phase=%s song_pos=%.3f score=%d combo=%d voltage=%.2f" % [g.phase, Audio.song_pos, g.score, g.combo, g.voltage]
