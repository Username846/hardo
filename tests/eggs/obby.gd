extends RefCounted
## Obby secret: tap the sun (it's up there in the first two stages) five times.

var tmr := 0.0
var taps := 0


func drive(bot: Node, g: Node, dt: float) -> void:
	# keep running and jumping like normal
	bot._drive(6, dt)
	if not g.running or g.locked or g.stage >= 2 or g.crown:
		return
	# poke it quickly while still on the long start platform
	tmr += dt
	if tmr < 0.12:
		return
	tmr = 0.0
	taps += 1
	g.press(g.SUN + Vector2(randf_range(-20, 20), randf_range(-20, 20)))
