extends RefCounted
## Secret test for MIKAKE KARAOKE: play along for a bit, then tap Mikake's leek five times in
## a row (like someone curious about the leek would).

var autopilot: Object = load("res://tests/bots/karaoke.gd").new()
var taps := 0
var tmr := 0.0


func drive(bot: Node, g: Node, dt: float) -> void:
	if g.phase == "cute" and Audio.song_pos > 8.0 and taps < 5:
		tmr += dt
		if tmr >= 0.25:
			tmr = 0.0
			taps += 1
			g.press(g._leek_center())
		return
	autopilot.drive(bot, g, dt)
