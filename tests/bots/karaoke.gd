extends RefCounted
## Autopilot for MIKAKE KARAOKE: press the right button when a ring lands, dance in the solos,
## then blow out the candles. With --kfail it first lets each song fail once (stops pressing
## until the voltage runs out); with --kkeys it presses A and D instead of tapping.

var tmr := 0.0
var dance_tmr := 0.0
var fail_first := false
var keys := false
# screenshots of the moments that matter (with --shots)
var snap_t := 0.0
var snaps := 0
var seen := {}


func _init() -> void:
	fail_first = "--kfail" in Game.main._args() or "--kfail=" in Game.main._args()
	keys = "--kkeys" in Game.main._args() or "--kkeys=" in Game.main._args()


func drive(bot: Node, g: Node, dt: float) -> void:
	tmr += dt
	_shots(bot, g, dt)
	if g.phase == "cute" or g.phase == "dark":
		if fail_first and int(g.fails.get(g.song, 0)) == 0:
			return
		if g._free_time():
			dance_tmr += dt
			if dance_tmr > 0.7:
				dance_tmr = 0.0
				g.press(Vector2(200 if randf() < 0.5 else 1080, 640))
			return
		var now: float = Audio.song_pos
		for k in range(g._lo, g.chart.size()):
			if float(g.chart[k][0]) - now > 0.1:
				break
			if not g.hits.has(k) and absf(float(g.chart[k][0]) - now) < 0.05:
				if keys:
					for down in [true, false]:
						var ev := InputEventKey.new()
						ev.keycode = KEY_A if g._lane[k] == 0 else KEY_D
						ev.pressed = down
						Input.parse_input_event(ev)
				else:
					g.press(Vector2(200 if g._lane[k] == 0 else 1080, 640))
				break
	elif g.phase == "candles" and tmr > 0.4 and not g.locked:
		tmr = 0.0
		for c in g.candles:
			if c.lit:
				g.press(Vector2(c.x, 400))
				break


func _shots(bot: Node, g: Node, dt: float) -> void:
	var key := ""
	if g.phase == "fail" and g.fail_k > 0.9:
		key = "fail_" + g.song
	elif g.dance != "" and g.dance_t > g.dance_len * 0.3:
		key = "dance_%s_%s" % [g.song, g.dance]
	elif g.phase == "grey" and g.gloom > 0.9:
		key = "grey"
	if key != "" and not seen.has(key):
		seen[key] = true
		bot._snap("k_" + key)
	if g.phase == "candles_wait" or g.phase == "candles":
		snap_t += dt
		if snap_t > 0.6:
			snap_t = 0.0
			snaps += 1
			bot._snap("k_candles_%02d" % snaps)


func dbg(g: Node) -> String:
	return "phase=%s song_pos=%.3f score=%d combo=%d voltage=%.2f fails=%s dance=%s" % [g.phase, Audio.song_pos, g.score, g.combo, g.voltage, g.fails, g.dance]
